import SwiftUI
import UIKit

@available(*, deprecated, message: "Use NewCircularProgressIndicator instead")
struct CircularProgressIndicatorView: UIViewRepresentable {
    private let backgroundColor: UIColor
    private let foregroundColor: UIColor

    init(
        backgroundColor: UIColor = .init(resource: .night),
        foregroundColor: UIColor = .init(resource: .lime)
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    func makeUIView(context _: Context) -> CircularProgressIndicator {
        let indicator = CircularProgressIndicator(
            backgroundCircularColor: backgroundColor,
            foregroundCircularColor: foregroundColor
        )
        return indicator
    }

    func updateUIView(_: CircularProgressIndicator, context _: Context) {}
}
