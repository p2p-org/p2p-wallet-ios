import SwiftUI

/// A theme for ``NewTextButton``
struct NewTextButtonAppearance {
    /// A background color of button.
    let backgroundColor: Color

    /// A foreground color of button. This value affects to title and icon. Icon should be rendered as template to have
    /// effect.
    let foregroundColor: Color

    /// A font of title
    let font: Font

    /// A border radius of button
    let borderRadius: CGFloat

    /// A background color for circular progress indicator
    let loadingBackgroundColor: Color

    /// A background color for circular progress indicator
    let loadingForegroundColor: Color

    /// A border color
    let borderColor: Color?

    /// A border color
    let borderWidth: CGFloat?

    init(
        backgroundColor: Color,
        foregroundColor: Color,
        font: Font,
        borderRadius: CGFloat,
        loadingBackgroundColor: Color,
        loadingForegroundColor: Color,
        borderColor: Color?,
        borderWidth: CGFloat?
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.font = font
        self.borderRadius = borderRadius
        self.loadingBackgroundColor = loadingBackgroundColor
        self.loadingForegroundColor = loadingForegroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
}
