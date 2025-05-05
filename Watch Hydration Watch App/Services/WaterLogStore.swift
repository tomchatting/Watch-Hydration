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

	private let calendar = Calendar.current
	private let storageKey = "WaterLogStore.today"

	init() {
		load()
	}

	func log(amount: Double) {
		let hour = calendar.component(.hour, from: Date())
		todayLogs[hour, default: 0] += amount
		save()
	}

	func totalToday() -> Double {
		todayLogs.values.reduce(0, +)
	}

	private func save() {
		if let data = try? JSONEncoder().encode(todayLogs) {
			UserDefaults.standard.set(data, forKey: storageKey)
		}
	}

	private func load() {
		guard let data = UserDefaults.standard.data(forKey: storageKey),
		      let logs = try? JSONDecoder().decode([Int: Double].self, from: data)
		else { return }

		// Only keep today’s logs
		let today = calendar.startOfDay(for: Date())
		let savedDate = UserDefaults.standard.object(forKey: "\(storageKey).date") as? Date ?? today
		if calendar.isDate(savedDate, inSameDayAs: today) {
			todayLogs = logs
		}
	}

	func resetForNewDay() {
		todayLogs = [:]
		UserDefaults.standard.set(Date(), forKey: "\(storageKey).date")
		save()
	}
}
