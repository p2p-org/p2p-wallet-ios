import Foundation
import UIKit

/// A theme for ``TextButton``
struct TextButtonAppearance {
    /// A background color of button.
    let backgroundColor: UIColor

    /// A foreground color of button. This value affects to title and icon. Icon should be rendered as template to have
    /// effect.
    let foregroundColor: UIColor

    /// A font of title
    let font: UIFont

    /// A content padding.
    let contentPadding: UIEdgeInsets

    /// A spacing between icons and title
    let iconSpacing: CGFloat

    /// A border radius of button
    let borderRadius: CGFloat

    /// A background color for circular progress indicator
    let loadingBackgroundColor: UIColor

    /// A background color for circular progress indicator
    let loadingForegroundColor: UIColor

    /// A border color
    let borderColor: UIColor?

    init(
        backgroundColor: UIColor,
        foregroundColor: UIColor,
        font: UIFont,
        contentPadding: UIEdgeInsets,
        iconSpacing: CGFloat,
        borderRadius: CGFloat,
        loadingBackgroundColor: UIColor,
        loadingForegroundColor: UIColor,
        borderColor: UIColor?
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.font = font
        self.contentPadding = contentPadding
        self.iconSpacing = iconSpacing
        self.borderRadius = borderRadius
        self.loadingBackgroundColor = loadingBackgroundColor
        self.loadingForegroundColor = loadingForegroundColor
        self.borderColor = borderColor
    }

    static func `default`() -> Self {
        .init(
            backgroundColor: UIColor(resource: .night),
            foregroundColor: UIColor(resource: .lime),
            font: .systemFont(ofSize: 16, weight: .medium),
            contentPadding: .init(top: 0, left: 28, bottom: 0, right: 20),
            iconSpacing: 12,
            borderRadius: 12,
            loadingBackgroundColor: UIColor(resource: .night),
            loadingForegroundColor: UIColor(resource: .snow),
            borderColor: nil
        )
    }

    /// Create a new appearance with new value.
    func copy(
        backgroundColor: UIColor? = nil,
        foregroundColor: UIColor? = nil
    ) -> Self {
        .init(
            backgroundColor: backgroundColor ?? self.backgroundColor,
            foregroundColor: foregroundColor ?? self.foregroundColor,
            font: font,
            contentPadding: contentPadding,
            iconSpacing: iconSpacing,
            borderRadius: borderRadius,
            loadingBackgroundColor: loadingBackgroundColor,
            loadingForegroundColor: loadingForegroundColor,
            borderColor: borderColor
        )
    }
}
