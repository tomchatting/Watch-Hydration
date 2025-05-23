//
//  WaterProgressView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI
import HealthKit

struct WaterProgressView: View {
    @EnvironmentObject private var viewModel: HydrationViewModel
    @State private var forceRefresh = UUID()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        let progressRatio = viewModel.waterIntakeService.progress
        let progressTrim = min(progressRatio, 1.0)

        ScrollView {
            VStack(spacing: 20) {
                waterProgressCircle(progressTrim: progressTrim)
                goalText
                motivationalMessage

                VStack(alignment: .leading, spacing: 0) {
                    timelineEntries
                }
            }
            .padding()
            .id(forceRefresh)
        }
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        Task {
            await viewModel.refreshData()
            await MainActor.run {
                forceRefresh = UUID()
            }
        }
    }

    private var goalText: some View {
        Text("Goal: \(viewModel.goalFormatted)")
            .font(.footnote)
            .foregroundColor(.secondary)
    }
    
    private var motivationalMessage: some View {
        Text(viewModel.motivationalMessage)
            .font(.caption)
            .foregroundColor(viewModel.progressColor)
            .multilineTextAlignment(.center)
    }

    private func waterProgressCircle(progressTrim: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: progressTrim)
                .stroke(viewModel.progressColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack {
                Text(viewModel.totalFormatted)
                    .font(.title3)
                    .bold()
                Text(viewModel.progressPercentage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120, height: 120)
    }

    private var timelineEntries: some View {
        ForEach(viewModel.waterIntakeService.todaysEntries.filter { $0.amount > 0 }) { entry in
            timelineEntryView(for: entry)
        }
    }

    private func timelineEntryView(for entry: WaterLogEntry) -> some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Rectangle()
                    .frame(width: 2)
                    .foregroundColor(.white)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(entry.amount)) mL")
                    .bold()
                Text(timeFormatter.string(from: entry.date))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding([.bottom, .trailing], 10)
            }
        }
    }
}
