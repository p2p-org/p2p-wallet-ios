//
//  Spinner.swift
//  p2p_wallet
//
//  Created by Ivan on 04.10.2022.
//

import SwiftUI

struct Spinner: View {
    let rotationTime: Double = 0.75
    static let initialDegree: Angle = .degrees(270)

    let color: Color = .init(.lightSea)
    let activePartColor: Color = .init(.sea)

    @State var rotationDegree = initialDegree

    var body: some View {
        ZStack {
            SpinnerCircle(start: 0, end: 1, rotation: Angle.degrees(0), color: color)
            SpinnerCircle(start: 0, end: 0.25, rotation: rotationDegree, color: activePartColor)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: rotationTime).repeatForever(autoreverses: false)) {
                rotationDegree = Angle.degrees(270 + 360)
            }
        }
    }
}

private struct SpinnerCircle: View {
    let start: CGFloat
    let end: CGFloat
    let rotation: Angle
    let color: Color

    var body: some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .fill(color)
            .rotationEffect(rotation)
    }
}
