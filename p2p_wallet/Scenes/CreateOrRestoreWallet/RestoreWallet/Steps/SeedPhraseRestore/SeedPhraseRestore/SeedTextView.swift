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

// struct SeedPhraseTextView: UIViewRepresentable {
//
//    @Binding var text: String
//
//    func makeUIView(context: Context) -> UITextView {
//        print(context)
//        let textView = UITextView()
//    //        textView.delegate = context.coordinator
//        return textView
//    }
//
//    func updateUIView(_ uiView: UITextView, context _: Context) {
//        print(uiView)
//    //        uiView.attributedText = context.coordinator.textReducer(text: text)
//    }
//
//    typealias UIViewType = UITextView
//
//    // MARK: -
//
//    final class Coordinator: NSObject, UITextViewDelegate {
//        var text: Binding<String>
//
//        init(text: Binding<String>) {
//            self.text = text
//        }
//
//        func textViewDidChange(_ textView: UITextView) {
//            if textView.attributedText.string != text.wrappedValue.string {
//                let string = textReducer(text: textView.attributedText.string)
//                text.wrappedValue = string.string
//
//                textView.attributedText = string
//            }
//        }
//
//        //        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        //            let newText = textView.attributedText.string.
//        //            return true
//        //        }
//
//        func textReducer(text: String) -> NSMutableAttributedString {
//            let needsSpace = text.last == " "
//            let words = text
//                .components(separatedBy: CharacterSet.decimalDigits).joined(separator: " ")
//                .split(separator: " ")
//            let string = NSMutableAttributedString()
//            for (index, word) in words.enumerated() {
//                let index = NSAttributedString.attributedString(with: String(index + 1), of: .text4)
//                    .withForegroundColor(Asset.Colors.mountain.color)
//                string.append(index)
//
//                let padding4 = NSTextAttachment()
//                padding4.bounds = CGRect(x: 0, y: 0, width: 4, height: 0)
//                string.append(NSAttributedString(attachment: padding4))
//
//                let wordString = NSAttributedString.attributedString(with: String(word), of: .text3)
//                string.append(wordString)
//
//                let padding16 = NSTextAttachment()
//                padding16.bounds = CGRect(x: 0, y: 0, width: 16, height: 0)
//                string.append(NSAttributedString(attachment: padding16))
//            }
//            if needsSpace {
//                string.appending(.init(string: " "))
//            }
//
//            return string
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(text: $text)
//    }
// }
