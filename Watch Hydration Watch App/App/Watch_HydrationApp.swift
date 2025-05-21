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
                    // Handle URL scheme from widget
                    if url.scheme == "watchhydration" {
                        // Navigate to the appropriate view if needed
                        print("App opened from widget or complication")
                    }
                }
        }
    }
}
