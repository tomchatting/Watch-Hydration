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
}
