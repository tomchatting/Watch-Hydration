//
//  WaterLogStore.swift
//  WaterBoy
//
//  Created by Thomas Chatting on 02/05/2025.
//

import Foundation
import SwiftUI

class WaterLogStore: ObservableObject {
	@Published var todayLogs: [Int: Double] = [:] // [hour: total ml]
    @Published var entries: [WaterLogEntry] = []

	private let calendar = Calendar.current
	private let storageKey = "WaterLogStore.today"

	init() {
		load()
	}

    func log(amount: Double, date: Date = Date()) {
        let entry = WaterLogEntry(date: date, amount: amount)
        entries.insert(entry, at: 0)
        save()
	}
    
    func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

	func totalToday() -> Double {
		todayLogs.values.reduce(0, +)
	}

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedEntries = try? JSONDecoder().decode([WaterLogEntry].self, from: data) {
            self.entries = savedEntries
        }
    }
    
    func syncToHealthKitIfAuthorized(healthKitStatus: HealthKitAuthStatus) {
        guard healthKitStatus.isAuthorized else { return }

        for entry in entries where Calendar.current.isDateInToday(entry.date) {
            HealthKitManager.shared.logWater(amountInML: entry.amount, date: entry.date)
        }
    }

	func resetForNewDay() {
		todayLogs = [:]
		UserDefaults.standard.set(Date(), forKey: "\(storageKey).date")
		save()
	}
}
