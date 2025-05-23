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
                .environment(\.waterIntakeService, DIContainer.shared.createWaterIntakeService())
                .configureHydrationApp()
        }
    }
}
