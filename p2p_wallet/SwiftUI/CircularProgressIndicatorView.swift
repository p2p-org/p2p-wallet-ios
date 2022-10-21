import KeyAppUI
import SwiftUI
import UIKit

struct CircularProgressIndicatorView: UIViewRepresentable {
    private let backgroundColor: UIColor
    private let foregroundColor: UIColor

    init(
        backgroundColor: UIColor = Asset.Colors.night.color,
        foregroundColor: UIColor = Asset.Colors.lime.color
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
