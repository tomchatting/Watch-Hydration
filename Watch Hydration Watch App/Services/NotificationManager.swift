//
//  NotificationManager.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import Foundation
import UserNotifications
import HealthKit

struct NotificationManager {
	static func requestAuthorizationIfNeeded() {
		let requestedKey = "didRequestNotificationPermission"
		let alreadyRequested = UserDefaults.standard.bool(forKey: requestedKey)
		guard !alreadyRequested else { return }

		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
			UserDefaults.standard.set(true, forKey: requestedKey)
			if granted {
				print("Notification permission granted")
			} else {
				print("Permission denied; will not ask again")
			}
		}
	}

	static func scheduleHydrationSummaryNotification(metGoal: Bool) {
		let content = UNMutableNotificationContent()
		content.title = "Hydration Summary"
		content.body = metGoal
			? "Great job hitting your hydration goal yesterday! 💧"
			: "Don’t forget to hydrate today. Let’s beat yesterday!"
		content.sound = .default

		var dateComponents = DateComponents()
		dateComponents.hour = 8

		let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
		let request = UNNotificationRequest(identifier: "dailyHydrationSummary", content: content, trigger: trigger)

		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				print("Error scheduling notification: \(error)")
			}
		}
	}
    
    static func scheduleHydrationSummaryIfNeeded(goal: Double = 2000) {
        let healthStore = HKHealthStore()
        let type = HKObjectType.quantityType(forIdentifier: .dietaryWater)!

        var start = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        start = Calendar.current.startOfDay(for: start)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            let total = (samples as? [HKQuantitySample])?.reduce(0.0) {
                $0 + $1.quantity.doubleValue(for: .literUnit(with: .milli))
            } ?? 0

            let metGoal = total >= goal

            scheduleHydrationSummaryNotification(metGoal: metGoal)
        }

        healthStore.execute(query)
    }
}
