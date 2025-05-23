//
//  HourlyHydrationData.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 23/05/2025.
//

import WidgetKit
import SwiftUI

// MARK: - Hourly Data Model

struct HourlyHydrationData: Codable {
    let hour: Int
    let amount: Double
    let timestamp: Date
    
    var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    var amPm: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Hourly Provider

struct HourlyHydrationProvider: TimelineProvider {
    let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared") ?? UserDefaults.standard
    
    func placeholder(in context: Context) -> HourlyHydrationEntry {
        HourlyHydrationEntry(
            date: Date(),
            hourlyData: generateSampleHourlyData(),
            totalToday: 1500,
            goal: 2000
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HourlyHydrationEntry) -> Void) {
        let hourlyData = loadHourlyData()
        let total = sharedDefaults.double(forKey: "hydrationTotal")
        let goal = sharedDefaults.double(forKey: "hydrationGoal") > 0 ? sharedDefaults.double(forKey: "hydrationGoal") : 2000
        
        let entry = HourlyHydrationEntry(
            date: Date(),
            hourlyData: hourlyData,
            totalToday: total,
            goal: goal
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HourlyHydrationEntry>) -> Void) {
        let hourlyData = loadHourlyData()
        let total = sharedDefaults.double(forKey: "hydrationTotal")
        let goal = sharedDefaults.double(forKey: "hydrationGoal") > 0 ? sharedDefaults.double(forKey: "hydrationGoal") : 2000
        
        let currentDate = Date()
        let entry = HourlyHydrationEntry(
            date: currentDate,
            hourlyData: hourlyData,
            totalToday: total,
            goal: goal
        )
        
        // Update more frequently - every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadHourlyData() -> [HourlyHydrationData] {
        // Try to load hourly data from shared defaults
        if let data = sharedDefaults.data(forKey: "hourlyHydrationData"),
           let hourlyData = try? JSONDecoder().decode([HourlyHydrationData].self, from: data) {
            
            // Filter to today's data only
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            return hourlyData.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        }
        
        // Return empty data if nothing found
        return []
    }
    
    private func generateSampleHourlyData() -> [HourlyHydrationData] {
        let currentHour = Calendar.current.component(.hour, from: Date())
        var data: [HourlyHydrationData] = []
        
        // Generate sample data for past hours today
        for hour in 6...currentHour {
            let amount = Double.random(in: 0...400)
            data.append(HourlyHydrationData(
                hour: hour,
                amount: amount,
                timestamp: Date()
            ))
        }
        
        return data
    }
}

// MARK: - Hourly Entry

struct HourlyHydrationEntry: TimelineEntry {
    let date: Date
    let hourlyData: [HourlyHydrationData]
    let totalToday: Double
    let goal: Double
    
    var maxHourlyAmount: Double {
        let amounts = hourlyData.map(\.amount).filter { $0 > 0 } // Only non-zero amounts
        return amounts.max() ?? 300 // Default to 300mL if no data
    }
    
    var currentHour: Int {
        return Calendar.current.component(.hour, from: date)
    }
    
    var progressPercent: Double {
        return min(totalToday / goal, 1.0)
    }
}

// MARK: - Hourly Chart View (Rectangular)

struct HourlyChartView: View {
    var entry: HourlyHydrationEntry
    
    private let totalHours = 12 // Show last 12 hours
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                    .font(.caption2)
                
                Text("\(Int(entry.progressPercent * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(entry.totalToday))mL")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            
            // Chart with timeline dividers
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(hourlyChartData.enumerated()), id: \.offset) { index, hourData in
                    HStack(spacing: 0) {
                        // Left divider (full height for first item, section divider for others)
                        Rectangle()
                            .fill(.tertiary)
                            .frame(width: index == 0 ? 1 : 0.5, height: index == 0 ? 25 : 20)
                        
                        // Content area with data bar
                        ZStack(alignment: .bottom) {
                            // Invisible background to maintain spacing
                            Rectangle()
                                .fill(.clear)
                                .frame(height: 25)
                            
                            // Data bar (only if there's volume)
                            if hourData.amount > 0 {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(barColor(for: hourData.amount))
                                    .frame(height: barHeight(for: hourData.amount))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right divider (full height for last item only)
                        if index == hourlyChartData.count - 1 {
                            Rectangle()
                                .fill(.tertiary)
                                .frame(width: 1, height: 25)
                        }
                    }
                }
            }
            .frame(height: 25)
            
            // Bottom labels
            HStack {
                Text("60m")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("now")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var barWidth: CGFloat {
        // Dynamically calculate bar width based on available space
        // Approximate widget width: ~160 points, minus padding
        let availableWidth: CGFloat = 148
        return max(6, availableWidth / CGFloat(totalHours) - 0.5)
    }
    
    private var hourlyChartData: [HourlyHydrationData] {
        let currentHour = Calendar.current.component(.hour, from: entry.date)
        var chartData: [HourlyHydrationData] = []
        
        // Create data for last 12 hours (including current hour)
        // This represents the last 60 minutes of each hour
        for i in stride(from: totalHours - 1, through: 0, by: -1) {
            let hour = (currentHour - i + 24) % 24 // Handle negative hours wrapping around
            
            if let existingData = entry.hourlyData.first(where: { $0.hour == hour }) {
                chartData.append(existingData)
            } else {
                // Create empty data for hours with no logging
                chartData.append(HourlyHydrationData(
                    hour: hour,
                    amount: 0,
                    timestamp: Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: entry.date) ?? entry.date
                ))
            }
        }
        
        return chartData
    }
    
    private func barHeight(for amount: Double) -> CGFloat {
        if amount == 0 {
            return 0 // No bar for empty hours
        }
        
        guard entry.maxHourlyAmount > 0 else { return 3 }
        let ratio = amount / entry.maxHourlyAmount
        return max(3, CGFloat(ratio) * 20) // Min height 3, max height 20
    }
    
    private func barColor(for amount: Double) -> Color {
        if amount < 100 {
            return .blue.opacity(0.5)
        } else if amount < 200 {
            return .blue.opacity(0.7)
        } else if amount < 300 {
            return .blue.opacity(0.9)
        } else {
            return .blue
        }
    }
}

// MARK: - Compact Hourly View (Circular)

struct CompactHourlyView: View {
    var entry: HourlyHydrationEntry
    
    var body: some View {
        ZStack {
            // Background progress ring
            Circle()
                .stroke(.tertiary, lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: entry.progressPercent)
                .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Center content
            VStack(spacing: 0) {
                // Mini bars showing last 3 hours
                HStack(spacing: 1) {
                    ForEach(lastThreeHours, id: \.hour) { hourData in
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(hourData.amount > 0 ? .blue : .gray.opacity(0.3))
                            .frame(width: 2, height: max(2, CGFloat(hourData.amount / entry.maxHourlyAmount) * 8))
                    }
                }
                
                // Current hour
                Text("\(entry.currentHour)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
    
    private var lastThreeHours: [HourlyHydrationData] {
        let currentHour = Calendar.current.component(.hour, from: entry.date)
        var threeHours: [HourlyHydrationData] = []
        
        // Get last 3 hours (including current)
        for hour in stride(from: currentHour, to: currentHour - 3, by: -1) {
            let adjustedHour = hour < 0 ? hour + 24 : hour
            
            if let existingData = entry.hourlyData.first(where: { $0.hour == adjustedHour }) {
                threeHours.append(existingData)
            } else {
                threeHours.append(HourlyHydrationData(
                    hour: adjustedHour,
                    amount: 0,
                    timestamp: entry.date
                ))
            }
        }
        
        return threeHours.reversed() // Show in chronological order
    }
}

// MARK: - Inline Hourly View

struct InlineHourlyView: View {
    var entry: HourlyHydrationEntry
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "drop.fill")
                .foregroundColor(.blue)
            
            Text("Last 3h:")
            
            ForEach(lastThreeHours, id: \.hour) { hourData in
                Text("\(Int(hourData.amount))")
                    .fontWeight(hourData.hour == entry.currentHour - 1 ? .semibold : .regular)
            }
            
            Text("mL")
        }
        .font(.caption2)
    }
    
    private var lastThreeHours: [HourlyHydrationData] {
        let currentHour = Calendar.current.component(.hour, from: entry.date)
        var threeHours: [HourlyHydrationData] = []
        
        // Get last 3 hours (including current)
        for hour in stride(from: currentHour, to: currentHour - 3, by: -1) {
            let adjustedHour = hour < 0 ? hour + 24 : hour
            
            if let existingData = entry.hourlyData.first(where: { $0.hour == adjustedHour }) {
                threeHours.append(existingData)
            } else {
                threeHours.append(HourlyHydrationData(
                    hour: adjustedHour,
                    amount: 0,
                    timestamp: entry.date
                ))
            }
        }
        
        return threeHours.reversed() // Show in chronological order
    }
}

// MARK: - Corner Hourly View

struct CornerHourlyView: View {
    var entry: HourlyHydrationEntry
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            // Current hour amount
            if let currentHourData = entry.hourlyData.first(where: { $0.hour == entry.currentHour }) {
                Text("\(Int(currentHourData.amount))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            } else {
                Text("0")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            // "mL" label
            Text("mL")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct HourlyHydrationWidget: Widget {
    let kind: String = "HourlyHydrationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HourlyHydrationProvider()) { entry in
            HourlyHydrationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hourly Hydration")
        .description("Track your hydration by hour with a detailed chart")
        .supportedFamilies([
            .accessoryRectangular,  // Main chart view
            .accessoryCircular,     // Compact view with mini bars
            .accessoryCorner,       // Current hour amount
            .accessoryInline        // Last 3 hours text
        ])
    }
}

// MARK: - Widget Entry View

struct HourlyHydrationWidgetEntryView: View {
    var entry: HourlyHydrationProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryRectangular:
            HourlyChartView(entry: entry)
        case .accessoryCircular:
            CompactHourlyView(entry: entry)
        case .accessoryCorner:
            CornerHourlyView(entry: entry)
        case .accessoryInline:
            InlineHourlyView(entry: entry)
        @unknown default:
            Text("Unsupported")
        }
    }
}

// MARK: - Helper Extension for Data Updates

extension UserDefaults {
    func setHourlyHydrationData(_ data: [HourlyHydrationData]) {
        if let encoded = try? JSONEncoder().encode(data) {
            set(encoded, forKey: "hourlyHydrationData")
            synchronize()
        }
    }
    
    func getHourlyHydrationData() -> [HourlyHydrationData] {
        guard let data = data(forKey: "hourlyHydrationData"),
              let decoded = try? JSONDecoder().decode([HourlyHydrationData].self, from: data) else {
            return []
        }
        return decoded
    }
}

// MARK: - Preview

#Preview("Rectangular", as: .accessoryRectangular) {
    HourlyHydrationWidget()
} timeline: {
    HourlyHydrationEntry(
        date: Date(),
        hourlyData: [
            HourlyHydrationData(hour: 8, amount: 250, timestamp: Date()),
            HourlyHydrationData(hour: 10, amount: 400, timestamp: Date()),
            HourlyHydrationData(hour: 12, amount: 150, timestamp: Date()),
            HourlyHydrationData(hour: 14, amount: 300, timestamp: Date()),
            HourlyHydrationData(hour: 16, amount: 200, timestamp: Date())
        ],
        totalToday: 1300,
        goal: 2000
    )
}

#Preview("Circular", as: .accessoryCircular) {
    HourlyHydrationWidget()
} timeline: {
    HourlyHydrationEntry(
        date: Date(),
        hourlyData: [
            HourlyHydrationData(hour: 14, amount: 300, timestamp: Date()),
            HourlyHydrationData(hour: 15, amount: 200, timestamp: Date()),
            HourlyHydrationData(hour: 16, amount: 150, timestamp: Date())
        ],
        totalToday: 1300,
        goal: 2000
    )
}
