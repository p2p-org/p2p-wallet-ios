import SwiftUI
import UIKit

struct SeedTextView: UIViewRepresentable {
    @Binding private var isFirstResponder: Bool
    @Binding private var text: String
    private var configuration = { (_: UITextView) in }

    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        configuration: @escaping (UITextView) -> Void = { _ in }
    ) {
        self.configuration = configuration
        _text = text
        _isFirstResponder = isFirstResponder
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UITextView, context _: Context) {
        uiView.text = text
        configuration(uiView)
        switch isFirstResponder {
        case true: uiView.becomeFirstResponder()
        case false: uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator($text, isFirstResponder: $isFirstResponder)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var isFirstResponder: Binding<Bool>

        init(_ text: Binding<String>, isFirstResponder: Binding<Bool>) {
            self.text = text
            self.isFirstResponder = isFirstResponder
        }

        @objc func textViewDidChange(_ textField: UITextView) {
            text.wrappedValue = textField.text ?? ""
        }

        func textViewDidBeginEditing(_: UITextView) {
            isFirstResponder.wrappedValue = true
        }

        func textViewDidEndEditing(_: UITextView) {
            isFirstResponder.wrappedValue = false
        }

        func textView(_ textView: UITextView, shouldChangeTextIn _: NSRange, replacementText text: String) -> Bool {
            if text == "\n", textView.returnKeyType == .done {
                isFirstResponder.wrappedValue = false
                return false
            }
            return true
        }
    }
}
