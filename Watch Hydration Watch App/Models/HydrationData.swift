//
//  HydrationData.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//


//
//  HydrationData.swift
//  WaterBoy
//
//  Created by Thomas Chatting on 02/05/2025.
//


import Foundation

class HydrationData {
    static let shared = HydrationData()

    var consumed: Double = 0.0      // Amount of water consumed (in milliliters)
    var goal: Double = 2000.0       // Hydration goal (in milliliters, can be user-configurable)

    private init() { }  // Prevent initialization from outside (singleton pattern)
}
