// HydrationEntry.swift
import WidgetKit
import SwiftUI

// The entry that will be displayed in the widget
struct HydrationEntry: TimelineEntry {
    // Required by TimelineEntry protocol
    let date: Date
    
    // Hydration data
    let progressPercentage: Double
    let currentAmount: Double
    let goalAmount: Double
    
    // Computed property for progress as a value between 0 and 1
    var progress: Double {
        return min(1.0, progressPercentage)
    }
    
    // Computed property to determine if goal is met
    var goalMet: Bool {
        return progressPercentage >= 1.0
    }
}

// Provider class responsible for generating timeline entries
struct HydrationProvider: TimelineProvider {
    // Use shared container for UserDefaults
    private let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared") ?? UserDefaults.standard
    
    // Provides a placeholder entry for when the widget is first displayed
    func placeholder(in context: Context) -> HydrationEntry {
        // Sample data for placeholder
        return HydrationEntry(
            date: Date(),
            progressPercentage: 0.65,
            currentAmount: 1300,
            goalAmount: 2000
        )
    }
    
    // Provides a snapshot entry for the widget gallery or when quickly displaying the widget
    func getSnapshot(in context: Context, completion: @escaping (HydrationEntry) -> Void) {
        // For preview or when requesting a snapshot
        let entry = HydrationEntry(
            date: Date(),
            progressPercentage: 0.65,
            currentAmount: 1300,
            goalAmount: 2000
        )
        completion(entry)
    }
    
    // Provides the actual timeline of entries
    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationEntry>) -> Void) {
        // Load data from shared UserDefaults
        let currentAmount = sharedDefaults.double(forKey: "hydrationTotal")
        let goalAmount = sharedDefaults.double(forKey: "hydrationGoal")
        
        // Log values for debugging
        print("Widget reading from shared defaults - Total: \(currentAmount), Goal: \(goalAmount)")
        
        // Calculate progress percentage
        let actualGoal = goalAmount > 0 ? goalAmount : 2000 // Default to 2000ml if no goal set
        let progressPercentage = currentAmount / actualGoal
        
        // Create the entry with the loaded data
        let entry = HydrationEntry(
            date: Date(),
            progressPercentage: progressPercentage,
            currentAmount: currentAmount,
            goalAmount: actualGoal
        )
        
        // Create a timeline with one entry that refreshes in 30 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        
        completion(timeline)
    }
}

// Extension for sample data in previews
extension HydrationEntry {
    static var sampleData: HydrationEntry {
        HydrationEntry(
            date: Date(),
            progressPercentage: 0.65,
            currentAmount: 1300,
            goalAmount: 2000
        )
    }
    
    static var goalMetSample: HydrationEntry {
        HydrationEntry(
            date: Date(),
            progressPercentage: 1.0,
            currentAmount: 2000,
            goalAmount: 2000
        )
    }
    
    static var lowProgressSample: HydrationEntry {
        HydrationEntry(
            date: Date(),
            progressPercentage: 0.25,
            currentAmount: 500,
            goalAmount: 2000
        )
    }
}
