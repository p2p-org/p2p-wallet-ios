import UIKit

struct SliderButtonAppearance {
    /// A background color of button.
    let backgroundColor: UIColor

    /// A title color of button
    let titleColor: UIColor

    /// A font of title
    let font: UIFont

    /// An icon tint color
    let iconColor: UIColor

    /// An icon background color
    let iconBackgroundColor: UIColor

    /// Should be filled with gradient color or not
    let isGradient: Bool

    /// A progress color of button
    let progressColor: UIColor?

    init(
        backgroundColor: UIColor,
        titleColor: UIColor,
        font: UIFont,
        iconColor: UIColor,
        iconBackgroundColor: UIColor,
        isGradient: Bool,
        progressColor: UIColor?
    ) {
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.font = font
        self.iconColor = iconColor
        self.iconBackgroundColor = iconBackgroundColor
        self.isGradient = isGradient
        self.progressColor = progressColor
    }

    static func `default`() -> Self {
        .init(
            backgroundColor: UIColor(resource: .night),
            titleColor: UIColor(resource: .snow),
            font: .systemFont(ofSize: 16, weight: .semibold),
            iconColor: UIColor(resource: .night),
            iconBackgroundColor: UIColor(resource: .lime),
            isGradient: true,
            progressColor: nil
        )
    }
}
