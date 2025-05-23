//
//  HourlyHydrationData.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 23/05/2025.
//


//
//  SharedModels.swift
//  Watch Hydration
//
//  Created by Claude - Shared between app and widget
//

import Foundation

// MARK: - Hourly Data Model (Shared)

struct HourlyHydrationData: Codable, Identifiable {
    var id = UUID()
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
    
    var hourDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Widget Data Keys

struct WidgetDataKeys {
    static let hydrationTotal = "hydrationTotal"
    static let hydrationGoal = "hydrationGoal"
    static let hourlyHydrationData = "hourlyHydrationData"
    static let lastUpdated = "lastUpdated"
}

// MARK: - Extensions for Widget Data

extension UserDefaults {
    func setHourlyHydrationData(_ data: [HourlyHydrationData]) {
        if let encoded = try? JSONEncoder().encode(data) {
            set(encoded, forKey: WidgetDataKeys.hourlyHydrationData)
            set(Date(), forKey: WidgetDataKeys.lastUpdated)
            synchronize()
        }
    }
    
    func getHourlyHydrationData() -> [HourlyHydrationData] {
        guard let data = data(forKey: WidgetDataKeys.hourlyHydrationData),
              let decoded = try? JSONDecoder().decode([HourlyHydrationData].self, from: data) else {
            return []
        }
        
        // Filter to today's data only
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return decoded.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }
}
