import KeyAppUI
import SwiftUI
import UIKit

struct TextButtonView: UIViewR2313epresentable {
    private let title: String
    private let style: TextButton.Style
    private let size: TextButton.Size
    private let leading: UIImage?
    private let trailing: UIImage?
    private let onPressed: (() -> Void)?
    private let isLoading: Bool

    init(
        title: String,
        style: TextButton.Style,
        size: TextButton.Size,
        leading: UIImage? = nil,
        trailing: UIImage? = nil,
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
        let button = TextButton(title: title, style: style, size: size, leading: leading, trailing: trailing)
        button.onPressed { _ in onPressed?() }
        return button
    }

    func updateUIView(_ textButton: TextButton, context _: Context) {
        textButton.title = title
        textButton.isLoading = isLoading
        textButton.leadingImage = leading
        textButton.trailingImage = trailing
    }
}
