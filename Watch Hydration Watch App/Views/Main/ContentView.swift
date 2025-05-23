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
    @State private var appKey = UUID() // Key to force app recreation
    
    var body: some View {
        if !hasOnboarded {
            OnboardingView {
                // Mark onboarding as complete and force app restart
                hasOnboarded = true
                appKey = UUID() // This will recreate the entire app
            }
        } else {
            AppMainView()
                .id(appKey) // Force recreation when key changes
        }
    }
}

struct AppMainView: View {
    @State private var selectedTab = 0
    @StateObject private var viewModel = DIContainer.shared.createHydrationViewModel()
    
    var body: some View {
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
    
    private func setupApp() {
        Task {
            await viewModel.waterIntakeService.refreshData()
            
            // Handle notification setup
            NotificationManager.requestAuthorizationIfNeeded()
            
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .authorized {
                NotificationManager.scheduleHydrationSummaryIfNeeded()
            }
        }
    }
}

#Preview {
    ContentView()
}
