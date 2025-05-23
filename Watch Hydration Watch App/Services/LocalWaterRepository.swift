//
//  LocalWaterRepository.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 23/05/2025.
//

import Foundation

@MainActor
class LocalWaterRepository: WaterIntakeRepository {
    private var entries: [WaterLogEntry] = []
    private let storageKey = "WaterLogStore.entries"
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadEntries()
    }
    
    nonisolated func isAuthorized() -> Bool {
        return true // Local storage is always available
    }
    
    func requestPermissions() async throws -> Bool {
        return true // No permissions needed for local storage
    }
    
    func getTodaysEntries() async throws -> [WaterLogEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }
    
    func addEntry(_ entry: WaterLogEntry) async throws {
        entries.insert(entry, at: 0)
        try await saveEntries()
    }
    
    func clearTodaysEntries() async throws {
        let calendar = Calendar.current
        entries.removeAll { calendar.isDateInToday($0.date) }
        try await saveEntries()
    }
    
    // MARK: - Private Methods
    
    private func loadEntries() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decodedEntries = try? JSONDecoder().decode([WaterLogEntry].self, from: data) else {
            entries = []
            return
        }
        
        // Keep only last 30 days of data to prevent unlimited growth
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        entries = decodedEntries.filter { $0.date >= thirtyDaysAgo }
    }
    
    private func saveEntries() async throws {
        do {
            let data = try JSONEncoder().encode(entries)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            throw WaterTrackingError.saveFailed(error)
        }
    }
}
