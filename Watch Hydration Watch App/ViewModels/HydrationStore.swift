//
//  HydrationStore.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 21/05/2025.
//

import SwiftUI
import Combine

@MainActor
class HydrationStore: ObservableObject {
    @Published var logStore = WaterLogStore()
    @Published var healthKitStatus = HealthKitAuthStatus()
    @Published var progress = HydrationProgress()
    @Published var animationManager = BubbleConfettiManager()
    
    static let shared = HydrationStore()
    
    private init() {}
    
    func refreshData() async {
        await progress.loadToday()
        objectWillChange.send()
    }
}
