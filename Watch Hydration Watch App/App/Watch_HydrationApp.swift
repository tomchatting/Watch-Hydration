//
//  Watch_HydrationApp.swift
//  Watch Hydration Watch App
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI

@main
struct Watch_HydrationApp: App {
    @StateObject private var hydrationStore = HydrationStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hydrationStore)
                .onOpenURL { url in
                    if url.scheme == "watchhydration" {
                        print("App opened from widget or complication")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)) { _ in
                    Task {
                        HydrationStore.shared.logStore.refreshIfNeeded()
                        await HydrationStore.shared.refreshData()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillResignActiveNotification)) { _ in
                    Task {
                        await HydrationStore.shared.logStore.save()
                    }
                }
        }
    }
}
