import SwiftUI
import UIKit

struct FocusedTextField: UIViewRepresentable {
    @Binding private var isFirstResponder: Bool
    @Binding private var text: String
    private let validation: NSPredicate?
    private var configuration = { (_: UITextField) in }

    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        validation: NSPredicate? = nil,
        configuration: @escaping (UITextField) -> Void = { _ in }
    ) {
        self.configuration = configuration
        self.validation = validation
        _text = text
        _isFirstResponder = isFirstResponder
    }

    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.delegate = context.coordinator
        view.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.textViewDidChange),
            for: .editingChanged
        )
        return view
    }

    func updateUIView(_ uiView: UITextField, context _: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.isFirstResponder, !isFirstResponder {
            DispatchQueue.main.async { uiView.resignFirstResponder() }
        } else if !uiView.isFirstResponder, isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        }
        configuration(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator($text, isFirstResponder: $isFirstResponder, validation: validation)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var isFirstResponder: Binding<Bool>
        private let validation: NSPredicate?

        init(_ text: Binding<String>, isFirstResponder: Binding<Bool>, validation: NSPredicate? = nil) {
            self.text = text
            self.isFirstResponder = isFirstResponder
            self.validation = validation
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

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool
        {
            if string == "\n", textField.returnKeyType == .done {
                isFirstResponder.wrappedValue = false
                return false
            }

            if let text = textField.text, let textRange = Range(range, in: text) {
                let updatedText = text.replacingCharacters(in: textRange, with: string)
                if let validation = validation, !validation.evaluate(with: updatedText) {
                    return false
                }
            }
            return true
        }
    }
}
