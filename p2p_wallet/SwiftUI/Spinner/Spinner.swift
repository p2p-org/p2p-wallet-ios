import SwiftUI
import KeyAppUI

struct Spinner: View {

    let color: Color
    let activePartColor: Color

    let rotationTime: Double = 0.75
    static let initialDegree: Angle = .degrees(270)

    @State var rotationDegree = initialDegree

    init(color: Color = Color(asset: Asset.Colors.lightSea), activePartColor: Color = Color(asset: Asset.Colors.sea)) {
        self.color = color
        self.activePartColor = activePartColor
    }

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
