//
//  HkSampleHelper.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import HealthKit

func fetchWaterIntakeToday(completion: @escaping ([HKQuantitySample]) -> Void) {
    let healthStore = HKHealthStore()

    guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
        completion([])
        return
    }

    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictEndDate)

    let query = HKSampleQuery(sampleType: waterType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
        guard let samples = samples as? [HKQuantitySample], error == nil else {
            completion([])
            return
        }
        completion(samples)
    }

    healthStore.execute(query)
}
