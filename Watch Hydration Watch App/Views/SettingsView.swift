//
//  SettingsView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("hydrationGoal") private var goal: Double = 2000
    @StateObject private var healthKitStatus = HealthKitAuthStatus()
    let minGoal: Double = 500
    let maxGoal: Double = 3000
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var appBuild: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        VStack {
            VStack {
                Slider(value: $goal, in: minGoal...maxGoal, step: 100) {
                    Text("Goal: \(Int(goal)) mL")
                }
                .onChange(of: goal) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: "hydrationGoal")
                }

                Text("Goal: \(Int(goal)) mL")
                    .font(.caption)
                    .padding()
            }
            .padding()
            
            VStack {
                if healthKitStatus.isAuthorized {
                    Label("HealthKit enabled", systemImage: "heart.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.top, 5)
                } else {
                    Label("HealthKit enabled", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                        .padding(.top, 5)
                }
            }
            
            VStack {
                Text("Version: \(appVersion) (\(appBuild))")
                    .font(.caption2)
                Text("© 2025 Thomas Chatting")
                    .font(.caption2)
            }
        }
    }
}
