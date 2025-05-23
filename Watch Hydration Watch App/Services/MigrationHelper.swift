//
//  MigrationHelper.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 23/05/2025.
//

import Foundation

class MigrationHelper {
    static let shared = MigrationHelper()
    
    private let userDefaults = UserDefaults.standard
    private let migrationVersionKey = "MigrationVersion"
    private let currentMigrationVersion = 1
    
    private init() {}
    
    func performMigrationIfNeeded() async {
        let currentVersion = userDefaults.integer(forKey: migrationVersionKey)
        
        if currentVersion < currentMigrationVersion {
            await performMigration(from: currentVersion, to: currentMigrationVersion)
            userDefaults.set(currentMigrationVersion, forKey: migrationVersionKey)
        }
    }
    
    private func performMigration(from oldVersion: Int, to newVersion: Int) async {
        print("Migrating from version \(oldVersion) to \(newVersion)")
        
        // Migrate old WaterLogStore data to new format
        if oldVersion == 0 {
            await migrateFromV0ToV1()
        }
    }
    
    private func migrateFromV0ToV1() async {
        // Migrate old data structure to new repository pattern
        let oldStorageKey = "WaterLogStore.today"
        
        if let oldData = userDefaults.data(forKey: oldStorageKey),
           let oldEntries = try? JSONDecoder().decode([OldWaterLogEntry].self, from: oldData) {
            
            // Convert to new format
            let newEntries = oldEntries.map { oldEntry in
                WaterLogEntry(date: oldEntry.date, amount: oldEntry.amount)
            }
            
            // Save in new format
            let repository = await LocalWaterRepository()
            
            for entry in newEntries {
                try? await repository.addEntry(entry)
            }
            
            // Clean up old data
            userDefaults.removeObject(forKey: oldStorageKey)
            
            print("Migrated \(newEntries.count) entries from old format")
        }
    }
}

// MARK: - Old Data Structures (for migration purposes)
private struct OldWaterLogEntry: Codable {
    let date: Date
    let amount: Double
}

// MARK: - Usage in App Lifecycle
extension MigrationHelper {
    func runOnAppLaunch() async {
        await performMigrationIfNeeded()
    }
}
