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
    
    let xOffset: CGFloat = .random(in: -70...0)
    let size: CGFloat = .random(in: 5...15)
    let yStart: CGFloat = .random(in: -20...20)
    let yTravel: CGFloat = .random(in: 60...70)

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    @State private var yOffset: CGFloat = 0
    
    init(id: UUID, color: Color = .blue) {
        self.id = id
        self.color = color
    }
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.6))
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: xOffset, y: yStart - yOffset)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5)) {
                    scale = 1.2
                    opacity = 0
                    yOffset = yTravel
                }
            }
    }
}
