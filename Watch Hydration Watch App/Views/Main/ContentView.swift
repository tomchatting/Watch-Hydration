//
//  ContentView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var selectedTab = 0
    @StateObject private var viewModel = DIContainer.shared.createHydrationViewModel()
    
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
            .environmentObject(viewModel)
            .onAppear {
                setupApp()
            }
        }
    }
    
    private func setupApp() {
        Task {
            await viewModel.waterIntakeService.refreshData()
        }
        
        // Keep notification setup as is
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
