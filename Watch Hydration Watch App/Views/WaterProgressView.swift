//
//  WaterProgressView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI
import HealthKit

struct WaterProgressView: View {
    @StateObject private var healthKitStatus = HealthKitAuthStatus()
    @StateObject private var logStore = WaterLogStore()
    @StateObject private var progress = HydrationProgress()

    var body: some View {
        
        let progressRatio = progress.total / progress.goal
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
            .environmentObject(progress)
        }
        .onAppear {
            progress.loadToday()
        }
    }

    private var goalText: some View {
        Text("Goal: \(progress.goal < 1000 ? "\(Int(progress.goal)) mL" : "\(String(format: "%.2f", progress.goal / 1000)) L")")
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func waterProgressCircle(progressTrim: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: progressTrim)
                .stroke(progress.total / progress.goal >= 1.0 ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text(progress.total < 1000 ? "\(Int(progress.total)) mL" : "\(String(format: "%.2f", Double(progress.total/1000))) L")
                .font(.title3)
        }
        .frame(width: 80, height: 80)
    }

    private var timelineEntries: some View {
        ForEach(progress.entries.filter { $0.amount > 0 }) { entry in
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
            }
        }
    }

    // MARK: - Time Formatter

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
}
