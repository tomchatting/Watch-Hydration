//
//  CupFillShape.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 03/05/2025.
//

import SwiftUI

struct CupFillShape: Shape {
    var fillPercent: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let flare: CGFloat = 10

        let fillHeight = CGFloat(fillPercent) * height
        let baseY = height
        let topY = baseY - fillHeight

        let progress = fillHeight / height
        let topInset = flare * (1 - progress)

        let topLeft = CGPoint(x: topInset, y: topY)
        let topRight = CGPoint(x: width - topInset, y: topY)
        let bottomRight = CGPoint(x: width - flare, y: baseY)
        let bottomLeft = CGPoint(x: flare, y: baseY)

        path.move(to: bottomLeft)
        path.addLine(to: bottomRight)
        path.addLine(to: topRight)
        path.addLine(to: topLeft)
        path.closeSubpath()

        return path
    }
}
