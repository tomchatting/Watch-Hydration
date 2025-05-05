//
//  WaterProgressView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI
import HealthKit

struct WaterProgressView: View {
    @State private var total: Double = 0
    @State private var entries: [HKQuantitySample] = []
    @AppStorage("hydrationGoal") private var goal: Double = 2000

    var body: some View {
        let progress = total / goal
        let progressTrim = min(progress, 1)

        ScrollView {
            VStack(spacing: 20) {
                waterProgressCircle(progressTrim: progressTrim)

                goalText

                VStack(alignment: .leading, spacing: 0) {
                    timelineEntries
                }

            }
            .padding()
        }
        .onAppear {
            loadWaterSamples()
        }
    }

    private var goalText: some View {
        Text("Goal: \(goal < 1000 ? "\(Int(goal)) mL" : "\(String(format: "%.2f", goal / 1000)) L")")
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func waterProgressCircle(progressTrim: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: progressTrim)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text(total < 1000 ? "\(Int(total)) mL" : "\(String(format: "%.2f", Double(total/1000))) L")
                .font(.title3)
        }
        .frame(width: 80, height: 80)
    }

    private var timelineEntries: some View {
        ForEach(entries.filter { $0.quantity.doubleValue(for: .literUnit(with: .milli)) > 0 }, id: \.uuid) { sample in
            timelineEntryView(for: sample)
        }
    }

    private func timelineEntryView(for sample: HKQuantitySample) -> some View {
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
                let amount = sample.quantity.doubleValue(for: .literUnit(with: .milli))
                Text("\(Int(amount)) mL")
                    .bold()
                Text(timeFormatter.string(from: sample.startDate))
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

    // MARK: - Load Data

    private func loadWaterSamples() {
        HealthKitManager.shared.getTodayWaterSamples { samples in
            self.entries = samples.sorted(by: { $0.startDate > $1.startDate })
            self.total = samples.reduce(0) {
                $0 + $1.quantity.doubleValue(for: .literUnit(with: .milli))
            }
        }
    }
}
