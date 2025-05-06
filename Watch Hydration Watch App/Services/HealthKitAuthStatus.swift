//
//  HealthKitAuthStatus.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 06/05/2025.
//


import Foundation
import HealthKit
import Combine

final class HealthKitAuthStatus: ObservableObject {
	private let healthStore = HKHealthStore()
	private let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater)!

	@Published var isAuthorized: Bool = false

	init() {
		refreshStatus()
	}

	func refreshStatus() {
		guard HKHealthStore.isHealthDataAvailable() else {
			isAuthorized = false
			return
		}
		let status = healthStore.authorizationStatus(for: waterType)
		isAuthorized = (status == .sharingAuthorized)
	}

	func requestAuthorization() {
		healthStore.requestAuthorization(toShare: [waterType], read: [waterType]) { success, error in
			DispatchQueue.main.async {
				self.refreshStatus()
			}
		}
	}
}
