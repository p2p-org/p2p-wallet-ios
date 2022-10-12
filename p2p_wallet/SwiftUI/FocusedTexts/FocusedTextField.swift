import SwiftUI
import UIKit

struct FocusedTextField: UIViewRepresentable {
    @Binding private var isFirstResponder: Bool
    @Binding private var text: String
    private var configuration = { (_: UITextField) in }

    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        configuration: @escaping (UITextField) -> Void = { _ in }
    ) {
        self.configuration = configuration
        _text = text
        _isFirstResponder = isFirstResponder
    }

    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UITextField, context _: Context) {
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

    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var isFirstResponder: Binding<Bool>

        init(_ text: Binding<String>, isFirstResponder: Binding<Bool>) {
            self.text = text
            self.isFirstResponder = isFirstResponder
        }

        @objc func textViewDidChange(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_: UITextField) {
            isFirstResponder.wrappedValue = true
        }

        func textFieldDidEndEditing(_: UITextField) {
            isFirstResponder.wrappedValue = false
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn _: NSRange,
                       replacementString text: String) -> Bool
        {
            if text == "\n", textField.returnKeyType == .done {
                isFirstResponder.wrappedValue = false
                return false
            }
            return true
        }
    }
}
