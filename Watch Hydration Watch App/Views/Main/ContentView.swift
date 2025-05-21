//
//  ContentView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @AppStorage("hydrationGoal") private var goal: Double = 2000
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var selectedTab = 0
    
    private let defaultGoal: Double = 2000
    
    var body: some View {
        if !hasOnboarded {
            OnboardingView {
                hasOnboarded = true
            }
        } else {
            TabView(selection: $selectedTab) {
                WaterInputView()
                    .tabItem {
                        Label("Log", systemImage: "drop.fill")
                    }
                    .tag(0)
                
                WaterProgressView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.bar.fill")
                    }
                    .tag(1)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(2)
            }
            .onAppear {
                setupApp()
            }
        }
    }
    
    private func setupApp() {
        if goal == 0 {
            goal = defaultGoal
            UserDefaults.standard.set(goal, forKey: "hydrationGoal")
        }
        
        NotificationManager.requestAuthorizationIfNeeded()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                NotificationManager.scheduleHydrationSummaryIfNeeded()
            }
        }
    }
}

#Preview {
    ContentView()
}
