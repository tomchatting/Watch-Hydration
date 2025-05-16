//
//  HydrationProgress.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//

import SwiftUI
import HealthKit

@MainActor
class HydrationProgress: ObservableObject {
    @Published var total: Double = 0
    @Published var entries: [WaterLogEntry] = []
    @AppStorage("hydrationGoal") var goal: Double = 2000

    private let healthKitStatus = HealthKitAuthStatus()
    private let logStore = WaterLogStore()

    func loadToday() async {
        if healthKitStatus.isAuthorized {
            let samples = await HealthKitManager.shared.getTodayWaterSamples()

            let mapped = samples.map {
                WaterLogEntry(
                    date: $0.startDate,
                    amount: $0.quantity.doubleValue(for: HKUnit.literUnit(with: .milli))
                )
            }.sorted(by: { $0.date > $1.date })

            self.entries = mapped
            self.total = mapped.reduce(0) { $0 + $1.amount }
        } else {
            let localEntries = logStore.entries.filter {
                Calendar.current.isDateInToday($0.date)
            }.sorted(by: { $0.date > $1.date })

            self.entries = localEntries
            self.total = localEntries.reduce(0) { $0 + $1.amount }
        }
    }
}
