//
//  WaterLogEntry.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 06/05/2025.
//

import SwiftUI

struct WaterLogEntry: Codable, Identifiable {
    var id = UUID()
	let date: Date
	let amount: Double
}
