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
        
        // Register for complication updates
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let complications = complicationServer.activeComplications {
            for complication in complications {
                complicationServer.reloadTimeline(for: complication)
            }
        }
        
        // Schedule background refresh
        scheduleBackgroundRefresh()
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
    
    func scheduleBackgroundRefresh() {
        // Schedule background refresh every hour
        let refreshInterval: TimeInterval = 60 * 5 // 5 minutes
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date(timeIntervalSinceNow: refreshInterval),
            userInfo: nil
        ) { (error) in
            if let error = error {
                print("Background refresh scheduling error: \(error.localizedDescription)")
            }
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Update complications
                let complicationServer = CLKComplicationServer.sharedInstance()
                if let complications = complicationServer.activeComplications {
                    for complication in complications {
                        complicationServer.reloadTimeline(for: complication)
                    }
                }
                
                // Schedule next refresh
                scheduleBackgroundRefresh()
                
                // Mark task complete
                backgroundTask.setTaskCompletedWithSnapshot(false)
                
            default:
                // Make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
