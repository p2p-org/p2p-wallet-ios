import SwiftUI
import KeyAppUI
import UIKit

struct SendInputAmountField: UIViewRepresentable {
    @Binding private var isFirstResponder: Bool
    @Binding private var text: String
    @Binding private var textColor: UIColor
    @Binding private var countAfterDecimalPoint: Int
    private var configuration = { (_: UITextField) in }

    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        countAfterDecimalPoint: Binding<Int>,
        textColor: Binding<UIColor>,
        configuration: @escaping (UITextField) -> Void = { _ in }
    ) {
        self.configuration = configuration
        _text = text
        _isFirstResponder = isFirstResponder
        _textColor = textColor
        _countAfterDecimalPoint = countAfterDecimalPoint
    }

    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.delegate = context.coordinator
        view.keyboardType = .decimalPad
        view.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.textViewDidChange),
            for: .editingChanged
        )
        view.textColor = textColor
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
        uiView.textColor = textColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFirstResponder: $isFirstResponder, countAfterDecimalPoint: $countAfterDecimalPoint)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isFirstResponder: Bool
        @Binding var countAfterDecimalPoint: Int

        init(text: Binding<String>, isFirstResponder: Binding<Bool>, countAfterDecimalPoint: Binding<Int>) {
            _text = text
            _isFirstResponder = isFirstResponder
            _countAfterDecimalPoint = countAfterDecimalPoint
        }

        @objc func textViewDidChange(_ textField: UITextField) {
            text = (textField.text ?? "").replacingOccurrences(of: ",", with: ".")
        }

        func textFieldDidBeginEditing(_: UITextField) {
            isFirstResponder = true
        }

        func textFieldDidEndEditing(_: UITextField) {
            isFirstResponder = false
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool
        {
            if string == "\n", textField.returnKeyType == .done {
                isFirstResponder = false
                return false
            }

            let decimalSeparator = "."
            let string = string.replacingOccurrences(of: ",", with: decimalSeparator)

            // if input comma (or dot)
            if textField.text?.isEmpty == true, string == decimalSeparator {
                textField.text = "0\(decimalSeparator)"
                return false
            }

            let currentText = textField.text ?? ""

            // attempt to read the range they are trying to change, or exit if we can't
            guard let stringRange = Range(range, in: currentText) else { return false }

            var updatedText = currentText.replacingCharacters(in: stringRange, with: string)

            // if deleting to the end otherwise we need to format
            if updatedText.isEmpty { return true }

            if updatedText.starts(with: "0") && !updatedText.starts(with: "0\(decimalSeparator)"), updatedText.count > 1 {
                // Not allow insert zeros before a number like 00004 or 00192
                updatedText = updatedText.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
            }

            let number = Double(updatedText.replacingOccurrences(of: " ", with: ""))

            if (string.isEmpty || string.starts(with: "0"))
                && updatedText.starts(with: "0\(decimalSeparator)")
                && number == 0 {
                // Allow to write 0,0000
                return isNotMaxSymbolsAfterSeparator(text: updatedText, string: string)
            }

            if string == decimalSeparator && number != nil {
                // Allow to write separator in any place if it is still a number like 7557.0 or 2.232
                return isNotMaxSymbolsAfterSeparator(text: updatedText, string: string)
            }

            if (string == "0" || string.isEmpty) && currentText.contains(decimalSeparator) {
                // Allow to write zeros in the end of number to expect another number after it like 0.84084
                return isNotMaxSymbolsAfterSeparator(text: updatedText, string: string)
            }

            // Format any number without
            if let number = number {
                textField.text = number.toString(maximumFractionDigits: countAfterDecimalPoint, roundingMode: .down)
                text = textField.text ?? ""
                return false
            }

            return false
        }

        private func isNotMaxSymbolsAfterSeparator(text: String, string: String) -> Bool {
            if string.isEmpty {
                // Validate only on insert
                return true
            }
            let parts = text.components(separatedBy: ".")
            guard parts.count == 2 else {
                return true
            }
            return parts[1].count <= countAfterDecimalPoint
        }
    }
}
