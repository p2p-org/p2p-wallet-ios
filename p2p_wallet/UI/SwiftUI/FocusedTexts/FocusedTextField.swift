import KeyAppUI
import SwiftUI
import UIKit

struct FocusedTextField<T: UITextField>: UIViewRepresentable {
    @Binding private var isFirstResponder: Bool
    @Binding private var text: String
    @Binding private var textColor: UIColor
    private let validation: NSPredicate?
    private var configuration = { (_: T) in }

    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        textColor: Binding<UIColor> = Binding.constant(Asset.Colors.night.color),
        validation: NSPredicate? = nil,
        configuration: @escaping (T) -> Void = { _ in }
    ) {
        self.configuration = configuration
        self.validation = validation
        _text = text
        _isFirstResponder = isFirstResponder
        _textColor = textColor
    }

    func makeUIView(context: Context) -> T {
        let view = T()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.delegate = context.coordinator
        view.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.textViewDidChange),
            for: .editingChanged
        )
        view.textColor = textColor
        return view
    }

    func updateUIView(_ uiView: T, context _: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.isFirstResponder, !isFirstResponder {
            DispatchQueue.main.async { uiView.resignFirstResponder() }
        } else if !uiView.isFirstResponder, isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        }
        configuration(uiView)
        uiView.textColor = textColor
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
