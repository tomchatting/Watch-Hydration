//
//  BubbleView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//

import SwiftUI

struct BubbleView: View {
	let id: UUID
    let color: Color
    
	let xOffset: CGFloat = .random(in: -50...40)
	let size: CGFloat = .random(in: 8...20)
	@State private var scale: CGFloat = 0.5
	@State private var opacity: Double = 1.0

	var body: some View {
		Circle()
            .fill(color.opacity(0.6))
			.frame(width: size, height: size)
			.scaleEffect(scale)
			.opacity(opacity)
			.offset(x: xOffset, y: -30)
			.onAppear {
				withAnimation(.easeOut(duration: 0.8)) {
					scale = 1.5
					opacity = 0
				}
			}
	}
}
