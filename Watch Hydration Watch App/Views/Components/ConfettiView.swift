//
//  ConfettiView.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 13/05/2025.
//

import SwiftUI

struct ConfettiView: View {
    let count = 15

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                ConfettiPiece(angle: .degrees(Double.random(in: 0...360)), delay: Double(i) * 0.02)
            }
        }
    }
}

struct ConfettiPiece: View {
    let angle: Angle
    let delay: Double
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Rectangle()
            .fill(Color(hue: Double.random(in: 0...1), saturation: 0.8, brightness: 1.0))
            .frame(width: 4, height: 8)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.interpolatingSpring(stiffness: 30, damping: 6)) {
                        yOffset = -100
                        xOffset = .random(in: -60...60)
                        rotation = .random(in: -90...90)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeInOut(duration: 2.5)) {
                            yOffset = 160
                            xOffset += .random(in: -40...40)
                            rotation += .random(in: 180...360)
                        }
                    }
                }
            }
    }
}
