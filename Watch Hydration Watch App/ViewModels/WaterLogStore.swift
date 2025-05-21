//
//  WaterLogStore.swift
//  WaterBoy
//
//  Created by Thomas Chatting on 02/05/2025.
//

import Foundation
import SwiftUI
import Combine

class WaterLogStore: ObservableObject {
    @Published var todayLogs: [Int: Double] = [:] // [hour: total ml]
    @Published var entries: [WaterLogEntry] = []
    @Published var totalAmount: Double = 0  // Add this to track total directly

    private let calendar = Calendar.current
    private let storageKey = "WaterLogStore.today"
    private let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration") ?? UserDefaults.standard

    init() {
        load()
        updateTodayLogs() // Sync todayLogs with entries on initialization
        updateTotalAmount() // Calculate initial total
    }

    func log(amount: Double, date: Date = Date()) {
        let entry = WaterLogEntry(date: date, amount: amount)
        entries.insert(entry, at: 0)
        
        // Update both derived values
        updateTodayLogs()
        updateTotalAmount()
        
        // Save to both standard and shared UserDefaults
        save()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(entries) {
            // Save to both standard and shared UserDefaults
            UserDefaults.standard.set(data, forKey: storageKey)
            sharedDefaults.set(data, forKey: storageKey)
            
            // Also save the total amount for widgets and complications
            sharedDefaults.set(totalAmount, forKey: "hydrationTotal")
        }
        
        // Explicitly announce changes
        objectWillChange.send()
    }

    func totalToday() -> Double {
        return totalAmount
    }
    
    // Update the total amount value
    private func updateTotalAmount() {
        let todayEntries = entries.filter { calendar.isDateInToday($0.date) }
        totalAmount = todayEntries.reduce(0) { $0 + $1.amount }
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
        // Try to load from shared UserDefaults first, then fall back to standard
        var data = sharedDefaults.data(forKey: storageKey)
        if data == nil {
            data = UserDefaults.standard.data(forKey: storageKey)
        }
        
        if let loadedData = data,
           let savedEntries = try? JSONDecoder().decode([WaterLogEntry].self, from: loadedData) {
            self.entries = savedEntries
            updateTotalAmount()
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
        updateTotalAmount()
        UserDefaults.standard.set(Date(), forKey: "\(storageKey).date")
        sharedDefaults.set(Date(), forKey: "\(storageKey).date")
        save()
    }
    
    // New method to clear today's entries
    func clearTodayEntries() {
        // Remove all entries that are from today
        entries.removeAll { calendar.isDateInToday($0.date) }
        
        // Update derived values
        updateTodayLogs()
        updateTotalAmount()
        
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
