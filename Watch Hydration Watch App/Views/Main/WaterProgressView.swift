//
//  WaterProgressView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI
import HealthKit

struct WaterProgressView: View {
    @EnvironmentObject private var hydrationStore: HydrationStore
    
    // Add this to force view updates
    @State private var forceRefresh = UUID()
    
    // Cache formatter
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        let progressRatio = hydrationStore.progress.total / hydrationStore.progress.goal
        let progressTrim = min(progressRatio, 1.0)

        ScrollView {
            VStack(spacing: 20) {
                waterProgressCircle(progressTrim: progressTrim)
                goalText

                VStack(alignment: .leading, spacing: 0) {
                    timelineEntries
                }
            }
            .padding()
            // This forces the view to refresh when forceRefresh changes
            .id(forceRefresh)
        }
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        Task {
            await hydrationStore.refreshData()
            // Update on main thread
            await MainActor.run {
                // Force refresh the view
                forceRefresh = UUID()
            }
        }
    }

    private var goalText: some View {
        Text("Goal: \(hydrationStore.progress.goal < 1000 ? "\(Int(hydrationStore.progress.goal)) mL" : "\(String(format: "%.2f", hydrationStore.progress.goal / 1000)) L")")
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func waterProgressCircle(progressTrim: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: progressTrim)
                .stroke(hydrationStore.progress.total / hydrationStore.progress.goal >= 1.0 ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text(hydrationStore.progress.total < 1000 ? "\(Int(hydrationStore.progress.total)) mL" : "\(String(format: "%.2f", Double(hydrationStore.progress.total/1000))) L")
                .font(.title3)
        }
        .frame(width: 80, height: 80)
    }

    private var timelineEntries: some View {
        ForEach(hydrationStore.progress.entries.filter { $0.amount > 0 }) { entry in
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
