//
//  ExtensionDelegate.swift
//  Watch Hydration Watch App
//
//  Created by Thomas Chatting on 02/05/2025.
//

import WatchKit
import ClockKit
import HealthKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    private let healthKitRepository = HealthKitWaterRepository()

    func applicationDidFinishLaunching() {
        // Reload complications on launch
        reloadComplications()
        
        // Request HealthKit authorization if not already granted
        Task {
            await requestHealthKitAuthorizationIfNeeded()
        }
        
        // Schedule background refresh
        scheduleBackgroundRefresh()
    }
    
    private func requestHealthKitAuthorizationIfNeeded() async {
        // Only request if not already authorized
        guard !healthKitRepository.isAuthorized() else {
            print("HealthKit already authorized")
            return
        }
        
        do {
            let success = try await healthKitRepository.requestPermissions()
            if success {
                print("HealthKit authorized")
                // Reload complications after authorization
                reloadComplications()
            } else {
                print("HealthKit authorization denied")
            }
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }
    
    private func reloadComplications() {
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let complications = complicationServer.activeComplications {
            for complication in complications {
                complicationServer.reloadTimeline(for: complication)
            }
        }
    }
    
    func scheduleBackgroundRefresh() {
        let refreshInterval: TimeInterval = 60 * 60 // 1 hour
        
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date(timeIntervalSinceNow: refreshInterval),
            userInfo: nil
        ) { (error) in
            if let error = error {
                print("Background refresh scheduling error: \(error.localizedDescription)")
            } else {
                print("Background refresh scheduled successfully")
            }
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Handle background refresh
                handleBackgroundRefresh(backgroundTask)
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Handle snapshot refresh
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
                
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    private func handleBackgroundRefresh(_ backgroundTask: WKApplicationRefreshBackgroundTask) {
        Task {
            do {
                // Update widget data in shared UserDefaults if HealthKit is authorized
                if healthKitRepository.isAuthorized() {
                    let todaysEntries = try await healthKitRepository.getTodaysEntries()
                    let total = HydrationCalculator.calculateTotal(entries: todaysEntries)
                    
                    // Update shared UserDefaults for widgets
                    let sharedDefaults = UserDefaults(suiteName: AppConfiguration.appGroupIdentifier)
                    sharedDefaults?.set(total, forKey: "hydrationTotal")
                    sharedDefaults?.synchronize()
                    
                    print("Background refresh: Updated total to \(total)mL")
                }
                
                // Reload complications with fresh data
                reloadComplications()
                
                // Schedule next background refresh
                scheduleBackgroundRefresh()
                
                // Mark task as completed
                backgroundTask.setTaskCompletedWithSnapshot(false)
                
            } catch {
                print("Background refresh error: \(error.localizedDescription)")
                backgroundTask.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
