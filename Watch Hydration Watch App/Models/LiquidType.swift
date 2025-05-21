//
//  LiquidType.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI

struct LiquidType: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coefficient: Double
    let color: Color
    
    static let all: [LiquidType] = [
        LiquidType(name: "Water", coefficient: 1.0, color: .blue),
        LiquidType(name: "Coffee", coefficient: 0.8, color: .brown),
        LiquidType(name: "Juice", coefficient: 0.9, color: .orange),
        LiquidType(name: "Cola", coefficient: 0.9, color: .gray),
        LiquidType(name: "Green Tea", coefficient: 0.95, color: .green),
        LiquidType(name: "Black Tea", coefficient: 0.85, color: .brown),
        LiquidType(name: "Tea w/ milk", coefficient: 0.9, color: .gray)
    ]
    
    static var defaultLiquid: LiquidType {
        return all[0]
    }
}
