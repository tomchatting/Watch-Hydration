//
//  Watch_HydrationApp.swift
//  Watch Hydration Watch App
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI

@main
struct Watch_Hydration_Watch_AppApp: App {
    @StateObject private var hydrationStore = HydrationStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hydrationStore)
        }
    }
}
