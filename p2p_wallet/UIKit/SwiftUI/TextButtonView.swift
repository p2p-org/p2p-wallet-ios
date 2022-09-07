import KeyAppUI
import SwiftUI
import UIKit

struct TextButtonView: UIViewRepresentable {
    @Binding var titleBinding: String
    private let title: String
    private let style: TextButton.Style
    private let size: TextButton.Size
    private let leading: UIImage?
    private let trailing: UIImage?
    @Binding var trailingBinding: UIImage?
    @Binding var isEnabled: Bool
    private let onPressed: (() -> Void)?

    init(
        title: String,
        titleBinding: Binding<String>? = nil,
        style: TextButton.Style,
        size: TextButton.Size,
        leading: UIImage? = nil,
        trailing: UIImage? = nil,
        trailingBinding: Binding<UIImage?>? = nil,
        isEnabled: Binding<Bool>?,
        onPressed: (() -> Void)? = nil
    ) {
        self.title = title
        _titleBinding = titleBinding ??
            Binding<String>(get: { "" }, set: { _, _ in })
        self.style = style
        self.size = size
        self.leading = leading
        self.trailing = trailing
        _trailingBinding = trailingBinding ??
            Binding<UIImage?>(get: { nil }, set: { _, _ in })
        _isEnabled = isEnabled ?? Binding<Bool>(get: { true }, set: { _, _ in })
        self.onPressed = onPressed
    }

    func makeUIView(context _: Context) -> TextButton {
        let button = TextButton(title: title, style: style, size: size, leading: leading, trailing: trailing)
        button.onPressed { _ in onPressed?() }
        return button
    }

    func updateUIView(_ button: TextButton, context _: Context) {
        button.title = titleBinding
        button.trailingImage = trailingBinding
        button.isEnabled = isEnabled
    }
}
