//
//  WaterLogStore.swift
//  WaterBoy
//
//  Created by Thomas Chatting on 02/05/2025.
//

import Foundation
import SwiftUI
import Combine
import WidgetKit

@MainActor
class WaterLogStore: ObservableObject, @unchecked Sendable {
    @Published var todayLogs: [Int: Double] = [:]
    @Published var entries: [WaterLogEntry] = []
    @Published var totalAmount: Double = 0

    private let calendar = Calendar.current
    private let storageKey = "WaterLogStore.today"
    private let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared") ?? UserDefaults.standard

    init() {
        load()
        updateTodayLogs()
        updateTotalAmount()
    }

    // Make this async to ensure proper sequencing
    func log(amount: Double, date: Date = Date()) async {
        let entry = WaterLogEntry(date: date, amount: amount)
        entries.insert(entry, at: 0)
        
        updateTodayLogs()
        updateTotalAmount()
        
        // Wait for save to complete before returning
        await save()
    }
    
    // Make save async and remove the completion handler
    func save() async {
        let entries = self.entries // Capture values we need
        let totalAmount = self.totalAmount
        
        // Encode on background queue
        let encodedData = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                let data = try? JSONEncoder().encode(entries)
                continuation.resume(returning: data)
            }
        }
        
        // Save to UserDefaults on main actor (since UserDefaults isn't Sendable)
        if let data = encodedData {
            sharedDefaults.set(data, forKey: storageKey)
            sharedDefaults.set(totalAmount, forKey: "hydrationTotal")
            sharedDefaults.synchronize()
        }
        
        refreshComplications()
    }

    func totalToday() -> Double {
        return totalAmount
    }
    
    private func updateTotalAmount() {
        let todayEntries = entries.filter { calendar.isDateInToday($0.date) }
        totalAmount = todayEntries.reduce(0) { $0 + $1.amount }
    }
    
    private func updateTodayLogs() {
        todayLogs = [:]
        for entry in entries where calendar.isDateInToday(entry.date) {
            let hour = calendar.component(.hour, from: entry.date)
            todayLogs[hour, default: 0] += entry.amount
        }
    }

    private func load() {
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

    func resetForNewDay() async {
        updateTodayLogs()
        updateTotalAmount()
        UserDefaults.standard.set(Date(), forKey: "\(storageKey).date")
        sharedDefaults.set(Date(), forKey: "\(storageKey).date")
        
        await save()
    }
    
    func clearTodayEntries() async {
        entries.removeAll { calendar.isDateInToday($0.date) }
        
        updateTodayLogs()
        updateTotalAmount()
        
        await save()
        
        print("Cleared all entries for today. Total is now: \(totalToday())")
    }
    
    private func refreshComplications() {
        WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")
    }
    
    func entriesForToday() -> [WaterLogEntry] {
        return entries.filter { calendar.isDateInToday($0.date) }
    }
    
    func totalFor(date: Date) -> Double {
        let dateEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
        return dateEntries.reduce(0) { $0 + $1.amount }
    }
}
