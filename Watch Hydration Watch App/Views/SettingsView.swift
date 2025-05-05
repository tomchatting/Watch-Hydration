//
//  SettingsView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("hydrationGoal") private var goal: Double = 2000
    let minGoal: Double = 500
    let maxGoal: Double = 3000

    var body: some View {
        VStack {
            Slider(value: $goal, in: minGoal...maxGoal, step: 100) {
                Text("Goal: \(Int(goal)) mL")
            }

            Text("Goal: \(Int(goal)) mL")
                .font(.caption)
                .padding()

            Button("Save Goal") {
                UserDefaults.standard.set(goal, forKey: "hydrationGoal")
            }
            .padding()
            .tint(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}
