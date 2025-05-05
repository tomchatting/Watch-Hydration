//
//  ExtensionDelegate.swift
//  WaterBoy
//
//  Created by Thomas Chatting on 02/05/2025.
//


import WatchKit
import ClockKit
import HealthKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    let healthStore = HKHealthStore()

    func applicationDidFinishLaunching() {
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach { server.reloadTimeline(for: $0) }

        HealthKitManager.shared.requestAuthorization { success, error in
            if success {
                print("HealthKit authorized")
            } else {
                print("HealthKit failed: \(error?.localizedDescription ?? "Unknown")")
            }
        }
    }
    
    private func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }

        let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        let typesToShare: Set<HKSampleType> = [waterType]
        let typesToRead: Set<HKObjectType> = [waterType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("Error requesting HealthKit authorization: \(error.localizedDescription)")
                return
            }

            if success {
                print("HealthKit authorization granted.")
            } else {
                print("HealthKit authorization denied.")
            }
        }
    }

}
