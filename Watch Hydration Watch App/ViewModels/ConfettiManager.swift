//
//  BubbleConfettiManager.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//


import SwiftUI
import Combine

@MainActor
class ConfettiManager: ObservableObject {
    @Published var showConfetti = false
    
    func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.showConfetti = false
        }
    }
}
