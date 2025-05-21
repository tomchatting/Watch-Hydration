//
//  HydrationData.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import Foundation

class HydrationData {
    static let shared = HydrationData()

    var consumed: Double = 0.0
    var goal: Double = 2000.0

    private init() { }
}
