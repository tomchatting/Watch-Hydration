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

class WaterLogStore: ObservableObject {
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

    func log(amount: Double, date: Date = Date()) {
        let entry = WaterLogEntry(date: date, amount: amount)
        entries.insert(entry, at: 0)
        
        updateTodayLogs()
        updateTotalAmount()
        
        save { [weak self] in
            self?.refreshComplications()
        }
    }
    
    func save(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            if let data = try? JSONEncoder().encode(self.entries) {
                self.sharedDefaults.set(data, forKey: self.storageKey)
                self.sharedDefaults.set(self.totalAmount, forKey: "hydrationTotal")
                
                self.sharedDefaults.synchronize()

                DispatchQueue.main.async {
                    completion()
                }
            } else {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
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

    func resetForNewDay() {
        updateTodayLogs()
        updateTotalAmount()
        UserDefaults.standard.set(Date(), forKey: "\(storageKey).date")
        sharedDefaults.set(Date(), forKey: "\(storageKey).date")
        
        save { [weak self] in
            self?.refreshComplications()
        }
    }
    
    func clearTodayEntries() {
        entries.removeAll { calendar.isDateInToday($0.date) }
        
        updateTodayLogs()
        updateTotalAmount()
        
        save { [weak self] in
            self?.refreshComplications()
        }
        
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
