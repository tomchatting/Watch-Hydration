//
//  Watch_HydrationApp.swift
//  Watch Hydration Watch App
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI

@main
struct Watch_HydrationApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .configureHydrationApp()
                .task {
                    // Run migration on app launch if needed
                    await MigrationHelper.shared.runOnAppLaunch()
                }
        }
    }
}
