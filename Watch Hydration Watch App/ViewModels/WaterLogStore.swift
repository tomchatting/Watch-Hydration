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
        updateTodayLogs() // Sync todayLogs with entries on initialization
    }

    func log(amount: Double, date: Date = Date()) {
        let entry = WaterLogEntry(date: date, amount: amount)
        entries.insert(entry, at: 0)
        updateTodayLogs() // Update todayLogs when adding a new entry
        save()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func totalToday() -> Double {
        let todayEntries = entries.filter { calendar.isDateInToday($0.date) }
        return todayEntries.reduce(0) { $0 + $1.amount }
    }
    
    // Update todayLogs based on entries for today
    private func updateTodayLogs() {
        todayLogs = [:]
        for entry in entries where calendar.isDateInToday(entry.date) {
            let hour = calendar.component(.hour, from: entry.date)
            todayLogs[hour, default: 0] += entry.amount
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedEntries = try? JSONDecoder().decode([WaterLogEntry].self, from: data) {
            self.entries = savedEntries
        }
    }
    
    func syncToHealthKitIfAuthorized(healthKitStatus: HealthKitAuthStatus) {
        guard healthKitStatus.isAuthorized else { return }

        for entry in entries where calendar.isDateInToday(entry.date) {
            HealthKitManager.shared.logWater(amountInML: entry.amount, date: entry.date)
        }
    }

    func resetForNewDay() {
        // We don't want to clear all entries, just update todayLogs
        updateTodayLogs()
        UserDefaults.standard.set(Date(), forKey: "\(storageKey).date")
        save()
    }
    
    // New method to clear today's entries
    func clearTodayEntries() {
        // Remove all entries that are from today
        entries.removeAll { calendar.isDateInToday($0.date) }
        
        // Update todayLogs
        todayLogs = [:]
        
        // Save changes
        save()
        
        print("Cleared all entries for today. Total is now: \(totalToday())")
    }
    
    // Optional: Method to get entries from today only
    func entriesForToday() -> [WaterLogEntry] {
        return entries.filter { calendar.isDateInToday($0.date) }
    }
    
    // Optional: Method to get the total for a specific date
    func totalFor(date: Date) -> Double {
        let dateEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
        return dateEntries.reduce(0) { $0 + $1.amount }
    }
}
