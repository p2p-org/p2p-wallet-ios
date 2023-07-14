import SwiftUI

public struct NewCircularProgressIndicator: View {

    private let backgroundColor: Color
    private let foregroundColor: Color
    private let size: CGSize
    private let lineWidth: CGFloat

    @State private var isCircleRotating = true
    @State private var animateStart = false
    @State private var animateEnd = true

    public init(
        backgroundColor: Color,
        foregroundColor: Color,
        size: CGSize = CGSize(width: 24, height: 24),
        lineWidth: CGFloat = 2
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.size = size
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .fill(backgroundColor)
                .frame(width: size.width, height: size.height)

            Circle()
                .trim(from: animateStart ? 1/3 : 1/9, to: animateEnd ? 2/5 : 1)
                .stroke(lineWidth: lineWidth)
                .rotationEffect(.degrees(isCircleRotating ? 360 : 0))
                .frame(width: size.width, height: size.height)
                .foregroundColor(foregroundColor)
                .onAppear() {
                    withAnimation(Animation
                        .linear(duration: 1)
                        .repeatForever(autoreverses: false)) {
                            self.isCircleRotating.toggle()
                        }
                    withAnimation(Animation
                        .linear(duration: 1)
                        .delay(0.5)
                        .repeatForever(autoreverses: true)) {
                            self.animateStart.toggle()
                        }
                    withAnimation(Animation
                        .linear(duration: 1)
                        .delay(1)
                        .repeatForever(autoreverses: true)) {
                            self.animateEnd.toggle()
                        }
                }
        }
    }
}

// MARK: - Preview
struct NewCircularProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        NewCircularProgressIndicator(
            backgroundColor: .red.opacity(0.4),
            foregroundColor: .red,
            size: CGSize(width: 60, height: 60),
            lineWidth: 6
        )
    }
}
