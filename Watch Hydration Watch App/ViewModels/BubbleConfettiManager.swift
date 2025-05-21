//
//  BubbleConfettiManager.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//


import SwiftUI
import Combine

class BubbleConfettiManager: ObservableObject {
	@Published var bubbles: [UUID] = []
	@Published var showConfetti = false

	func triggerBubbles(count: Int = 6) {
		for _ in 0..<count {
			bubbles.append(UUID())
		}
		// Auto-clear after animation
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			self.bubbles.removeAll()
		}
	}

	func triggerConfetti() {
		showConfetti = true
		DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
			self.showConfetti = false
		}
	}
}
