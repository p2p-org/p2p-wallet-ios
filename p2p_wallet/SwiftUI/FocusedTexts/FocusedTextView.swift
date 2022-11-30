import SwiftUI
import UIKit
import KeyAppUI

struct FocusedTextView: UIViewRepresentable {
    @Binding private var isFirstResponder: Bool
    @Binding private var text: String

    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>
    ) {
        _text = text
        _isFirstResponder = isFirstResponder
    }

    func makeUIView(context: Context) -> SeedPhrasesTextView {
        let view = SeedPhrasesTextView()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.forwardedDelegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: SeedPhrasesTextView, context _: Context) {
//        uiView.text = text
        uiView.paste(text)
        switch isFirstResponder {
        case true: uiView.becomeFirstResponder()
        case false: uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator($text, isFirstResponder: $isFirstResponder)
    }

    class Coordinator: NSObject, SeedPhraseTextViewDelegate {
        var text: Binding<String>
        var isFirstResponder: Binding<Bool>

        init(_ text: Binding<String>, isFirstResponder: Binding<Bool>) {
            self.text = text
            self.isFirstResponder = isFirstResponder
        }
        
        func seedPhrasesTextView(_ textView: KeyAppUI.SeedPhrasesTextView, didEnterPhrases phrases: String) {
            text.wrappedValue = phrases
        }
        
        func seedPhrasesTextViewDidBeginEditing(_ textView: SeedPhrasesTextView) {
            isFirstResponder.wrappedValue = true
        }
        
        func seedPhrasesTextViewDidEndEditing(_ textView: SeedPhrasesTextView) {
            isFirstResponder.wrappedValue = false
        }
    }
}
