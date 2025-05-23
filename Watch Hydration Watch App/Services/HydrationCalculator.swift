//
//  HydrationCalculator.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 23/05/2025.
//

import Foundation

struct HydrationCalculator {
    
    // MARK: - Progress Calculations
    
    static func calculateProgress(entries: [WaterLogEntry], goal: Double) -> Double {
        let total = calculateTotal(entries: entries)
        guard goal > 0 else { return 0 }
        return min(total / goal, 1.0)
    }
    
    static func calculateTotal(entries: [WaterLogEntry]) -> Double {
        return entries.reduce(0) { $0 + $1.amount }
    }
    
    static func calculateRemaining(entries: [WaterLogEntry], goal: Double) -> Double {
        let total = calculateTotal(entries: entries)
        return max(goal - total, 0)
    }
    
    // MARK: - Time-based Analysis
    
    static func calculateHourlyDistribution(entries: [WaterLogEntry]) -> [Int: Double] {
        var hourlyDistribution: [Int: Double] = [:]
        
        for entry in entries {
            let hour = Calendar.current.component(.hour, from: entry.date)
            hourlyDistribution[hour, default: 0] += entry.amount
        }
        
        return hourlyDistribution
    }
    
    static func getEntriesForDate(_ date: Date, from entries: [WaterLogEntry]) -> [WaterLogEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    static func getTodaysEntries(from entries: [WaterLogEntry]) -> [WaterLogEntry] {
        return getEntriesForDate(Date(), from: entries)
    }
    
    // MARK: - Goal Analysis
    
    static func isGoalReached(entries: [WaterLogEntry], goal: Double) -> Bool {
        return calculateTotal(entries: entries) >= goal
    }
    
    static func calculateGoalPercentage(entries: [WaterLogEntry], goal: Double) -> Double {
        return calculateProgress(entries: entries, goal: goal) * 100
    }
    
    // MARK: - Statistics
    
    static func calculateAveragePerDay(entries: [WaterLogEntry], days: Int) -> Double {
        guard days > 0 else { return 0 }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let recentEntries = entries.filter { $0.date >= startDate }
        let total = calculateTotal(entries: recentEntries)
        
        return total / Double(days)
    }
    
    static func calculateStreakDays(entries: [WaterLogEntry], goal: Double) -> Int {
        let calendar = Calendar.current
        var streakDays = 0
        var currentDate = Date()
        
        // Check backwards from today
        while true {
            let dayEntries = getEntriesForDate(currentDate, from: entries)
            let dayTotal = calculateTotal(entries: dayEntries)
            
            if dayTotal >= goal {
                streakDays += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streakDays
    }
}
