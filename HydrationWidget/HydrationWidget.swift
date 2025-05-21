//
//  HydrationWidget.swift
//  Watch Hydration WidgetExtension
//
//  Created by Thomas Chatting on 21/05/2025.
//

import WidgetKit
import SwiftUI

// MARK: - Provider

struct Provider: TimelineProvider {
    let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared") ?? UserDefaults.standard
    
    func placeholder(in context: Context) -> HydrationEntry {
        HydrationEntry(date: Date(), total: 1500, goal: 2000)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HydrationEntry) -> Void) {
        let total = sharedDefaults.double(forKey: "hydrationTotal")
        let goal = sharedDefaults.double(forKey: "hydrationGoal") > 0 ? sharedDefaults.double(forKey: "hydrationGoal") : 2000
        
        let entry = HydrationEntry(date: Date(), total: total, goal: goal)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationEntry>) -> Void) {
        let total = sharedDefaults.double(forKey: "hydrationTotal")
        let goal = sharedDefaults.double(forKey: "hydrationGoal") > 0 ? sharedDefaults.double(forKey: "hydrationGoal") : 2000
        
        let currentDate = Date()
        let entry = HydrationEntry(date: currentDate, total: total, goal: goal)
        
        // Create a timeline that refreshes at the end of the day
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: currentDate) ?? currentDate.addingTimeInterval(86400)
        
        let timeline = Timeline(entries: [entry], policy: .after(endOfDay))
        completion(timeline)
    }
}

// MARK: - Entry

struct HydrationEntry: TimelineEntry {
    let date: Date
    let total: Double
    let goal: Double
    
    var progressPercent: Float {
        return Float(min(total / goal, 1.0))
    }
    
    var progressPercentInt: Int {
        return Int(progressPercent * 100)
    }
}

// MARK: - CircularSmallView

struct CircularPremiumView: View {
    var entry: HydrationEntry
    
    // SF Symbols configuration
    var dropSymbol: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: 11, weight: .semibold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, .blue)
    }
    
    var body: some View {
        ZStack {
            // Background gauge with dynamic blur effect
            Gauge(value: Double(entry.progressPercent)) {
                EmptyView()
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.blue)
            
            // Content layer
            VStack(spacing: 1) {
                // Water drop icon at top
                dropSymbol
                
                // Bold percentage
                Text("\(entry.progressPercentInt)%")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .shadow(color: .black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
            }
            .offset(y: -1) // Slight adjustment for visual balance
        }
        .containerBackground(.clear, for: .widget)
        .widgetAccentable()
    }
}

// MARK: - GraphicCircularView

struct GraphicCircularView: View {
    var entry: HydrationEntry
    
    var body: some View {
        Gauge(value: Double(entry.progressPercent)) {
            Text("\(entry.progressPercentInt)%")
                .font(.system(.title3, design: .rounded))
                .bold()
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.blue)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - GraphicCornerView (Clean & Minimal Design)

struct GraphicCornerView: View {
    var entry: HydrationEntry

    var body: some View {
        Gauge(value: Double(entry.progressPercent)) {
            Text("") // label
        } currentValueLabel: {
            Text("\(entry.progressPercentInt)%")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        } minimumValueLabel: {
            Text("")
        } maximumValueLabel: {
            Text("") // must be same type as others (Text)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.blue)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}


// MARK: - GraphicBezelView

struct GraphicBezelView: View {
    var entry: HydrationEntry
    
    var body: some View {
        VStack {
            Gauge(value: Double(entry.progressPercent)) {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.blue)
            
            Text("\(Int(entry.total)) / \(Int(entry.goal)) mL")
                .font(.system(.subheadline, design: .rounded))
                .bold()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Config

struct HydrationWidget: Widget {
    let kind: String = "HydrationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HydrationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hydration Progress")
        .description("Track your daily hydration progress")
        .supportedFamilies([
            .accessoryCircular,    // replaces .circularSmall and .graphicCircular
            .accessoryCorner,      // replaces .graphicCorner
            .accessoryInline,      // new inline text-only option
            .accessoryRectangular  // can replace .graphicBezel
        ])
    }
}

// MARK: - Widget Entry View

struct HydrationWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularPremiumView(entry: entry)
        case .accessoryCorner:
            GraphicCornerView(entry: entry)
        case .accessoryInline:
            Text("Hydration: \(entry.progressPercentInt)%")
        case .accessoryRectangular:
            GraphicBezelView(entry: entry)
        @unknown default:
            Text("Unsupported")
        }
    }
}

// MARK: - Preview

#Preview("Circular", as: .accessoryCircular) {
    HydrationWidget()
} timeline: {
    HydrationEntry(date: Date(), total: 1500, goal: 2000)
}

#Preview("Corner", as: .accessoryCorner) {
    HydrationWidget()
} timeline: {
    HydrationEntry(date: Date(), total: 1500, goal: 2000)
}

#Preview("Inline", as: .accessoryInline) {
    HydrationWidget()
} timeline: {
    HydrationEntry(date: Date(), total: 1500, goal: 2000)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    HydrationWidget()
} timeline: {
    HydrationEntry(date: Date(), total: 1500, goal: 2000)
}

// MARK: - Refresh Helper

extension WidgetCenter {
    static func refreshHydrationWidget() {
        // 1. Make sure all data is saved to UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared") ?? UserDefaults.standard
        
        // Directly read values from UserDefaults
        // Instead of using HydrationStore.shared, read existing values
        let total = sharedDefaults.double(forKey: "hydrationTotal")
        let goal = sharedDefaults.double(forKey: "hydrationGoal") > 0 ? sharedDefaults.double(forKey: "hydrationGoal") : 2000
        
        // Force synchronize
        sharedDefaults.synchronize()
        
        print("💧 Widget refreshing with data: \(total)/\(goal)")
        
        // 2. Refresh the widget
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ Refreshed hydration widget")
    }
}
