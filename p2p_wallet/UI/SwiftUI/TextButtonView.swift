import Combine
import KeyAppUI
import SwiftUI
import UIKit

@available(*, deprecated, message: "Use NewTextButton instead")
struct TextButtonView: UIViewRepresentable {
    private let title: String
    private let style: TextButton.Style
    private let size: TextButton.Size
    private let leading: ImageResource?
    private let trailing: ImageResource?
    private let onPressed: (() -> Void)?
    private let isLoading: Bool

    init(
        title: String,
        style: TextButton.Style,
        size: TextButton.Size,
        leading: ImageResource? = nil,
        trailing: ImageResource? = nil,
        isLoading: Bool = false,
        onPressed: (() -> Void)? = nil
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.leading = leading
        self.trailing = trailing
        self.onPressed = onPressed
        self.isLoading = isLoading
    }

    func makeUIView(context _: Context) -> TextButton {
        let button = TextButton(
            title: title,
            style: style,
            size: size,
            leading: leading == nil ? nil: .init(resource: leading!),
            trailing: trailing == nil ? nil: .init(resource: trailing!)
        )
        button.onPressed { _ in onPressed?() }
        return button
    }

    func updateUIView(_ textButton: TextButton, context _: Context) {
        textButton.title = title
        textButton.isLoading = isLoading
        if let leading {
            textButton.leadingImage = .init(resource: leading)
        } else {
            textButton.leadingImage = nil
        }
        if let trailing {
            textButton.trailingImage = .init(resource: trailing)
        } else {
            textButton.trailingImage = nil
        }
        textButton.onPressed { _ in onPressed?() }
    }
}
