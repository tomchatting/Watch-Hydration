//
//  HkSampleHelper.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import HealthKit

func fetchWaterIntakeToday(completion: @escaping ([HKQuantitySample]) -> Void) {
    let healthStore = HKHealthStore()

    // Define the quantity type for water
    guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
        completion([])
        return
    }

    // Get the current date and start and end of the day
    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

    // Create the predicate for the query to get data only for today
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictEndDate)

    // Perform the query
    let query = HKSampleQuery(sampleType: waterType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
        guard let samples = samples as? [HKQuantitySample], error == nil else {
            completion([])
            return
        }
        completion(samples)
    }

    healthStore.execute(query)
}
