//
//  WaveShape.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI

struct WaveShape: Shape {
	var offset: CGFloat
	var amplitude: CGFloat

	func path(in rect: CGRect) -> Path {
		var path = Path()
		let waveHeight = amplitude
		let wavelength = rect.width / 1.5

		path.move(to: .zero)

		for x in stride(from: 0, through: rect.width, by: 1) {
			let relativeX = x / wavelength
			let y = sin(relativeX * .pi * 2 + offset) * waveHeight + waveHeight
			path.addLine(to: CGPoint(x: x, y: y))
		}

		path.addLine(to: CGPoint(x: rect.width, y: rect.height))
		path.addLine(to: CGPoint(x: 0, y: rect.height))
		path.closeSubpath()

		return path
	}
}
