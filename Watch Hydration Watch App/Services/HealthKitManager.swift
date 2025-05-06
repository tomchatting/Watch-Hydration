//
//  HealthKitManager.swift
//  WaterBoy
//
//  Created by Thomas Chatting on 02/05/2025.
//


import HealthKit
import SwiftUI

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    @StateObject private var healthKitStatus = HealthKitAuthStatus()
    
    private init() {}
    
    var isWaterWriteAuthorized: Bool {
            guard HKHealthStore.isHealthDataAvailable() else { return false }
            let type = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
            let status = healthStore.authorizationStatus(for: type)
            return status == .sharingAuthorized
        }

    func requestAuthorization(completion: ((Bool, Error?) -> Void)? = nil) {
            guard HKHealthStore.isHealthDataAvailable(),
                  let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
                completion?(false, nil)
                return
            }

            let typesToShare: Set = [waterType]
            let typesToRead: Set = [waterType]

            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                completion?(success, error)
            }
        }

    func logWater(amountInML: Double, date: Date? = Date()) {
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amountInML)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date!, end: date!)

        healthStore.save(sample) { success, error in
            if let error = error {
                print("HealthKit save failed: \(error)")
            }
        }
    }
    
    func getTodayWaterSamples(completion: @escaping ([HKQuantitySample]) -> Void) {
        let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: waterType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            let quantitySamples = samples as? [HKQuantitySample] ?? []
            DispatchQueue.main.async {
                completion(quantitySamples)
            }
        }
        healthStore.execute(query)
    }

}
