//
//  WaterInputRepository.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 23/05/2025.
//

import Foundation
import HealthKit

// MARK: - Data Models
struct WaterLogEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    let date: Date
    let amount: Double // in mL
}

enum WaterTrackingError: Error {
    case healthKitUnavailable
    case authorizationDenied
    case saveFailed(Error)
    case loadFailed(Error)
}

// MARK: - Repository Protocol
protocol WaterIntakeRepository {
    func getTodaysEntries() async throws -> [WaterLogEntry]
    func addEntry(_ entry: WaterLogEntry) async throws
    func clearTodaysEntries() async throws
    func requestPermissions() async throws -> Bool
    func isAuthorized() -> Bool
}

// MARK: - HealthKit Repository
@MainActor
class HealthKitWaterRepository: WaterIntakeRepository {
    private let healthStore = HKHealthStore()
    private let waterType: HKQuantityType
    
    init() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            fatalError("Water type not available")
        }
        self.waterType = type
    }
    
    nonisolated func isAuthorized() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        return healthStore.authorizationStatus(for: waterType) == .sharingAuthorized
    }
    
    func requestPermissions() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw WaterTrackingError.healthKitUnavailable
        }
        
        // Check if already authorized to avoid unnecessary requests
        if isAuthorized() {
            return true
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let typesToShare: Set = [waterType]
            let typesToRead: Set = [waterType]
            
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: WaterTrackingError.saveFailed(error))
                } else {
                    // Re-check authorization status after request
                    // iOS may not grant permission even if no error occurred
                    let actuallyAuthorized = self.isAuthorized()
                    continuation.resume(returning: actuallyAuthorized)
                }
            }
        }
    }
    
    func getTodaysEntries() async throws -> [WaterLogEntry] {
        return try await withCheckedThrowingContinuation { continuation in
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: waterType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: WaterTrackingError.loadFailed(error))
                    return
                }
                
                let entries = (samples as? [HKQuantitySample] ?? []).map { sample in
                    WaterLogEntry(
                        date: sample.startDate,
                        amount: sample.quantity.doubleValue(for: .literUnit(with: .milli))
                    )
                }
                
                continuation.resume(returning: entries)
            }
            
            healthStore.execute(query)
        }
    }
    
    func addEntry(_ entry: WaterLogEntry) async throws {
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: entry.amount)
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: entry.date,
            end: entry.date
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.save(sample) { success, error in
                if let error = error {
                    continuation.resume(throwing: WaterTrackingError.saveFailed(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func clearTodaysEntries() async throws {
        let entries = try await getTodaysEntries()
        guard !entries.isEmpty else { return }
        
        // Convert back to HKSamples for deletion
        let samples = try await getCurrentHealthKitSamples()
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.delete(samples) { success, error in
                if let error = error {
                    continuation.resume(throwing: WaterTrackingError.saveFailed(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func getCurrentHealthKitSamples() async throws -> [HKSample] {
        return try await withCheckedThrowingContinuation { continuation in
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
            
            let query = HKSampleQuery(
                sampleType: waterType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: WaterTrackingError.loadFailed(error))
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            
            healthStore.execute(query)
        }
    }
}
