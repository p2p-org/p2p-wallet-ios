import SwiftUI
import UIKit

public struct SeedPhraseTextView: UIViewRepresentable {
    @Binding private var isFirstResponder: Bool
    @Binding private var text: String

    public init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>
    ) {
        _text = text
        _isFirstResponder = isFirstResponder
    }

    public func makeUIView(context: Context) -> UISeedPhrasesTextView {
        let view = UISeedPhrasesTextView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.forwardedDelegate = context.coordinator
        return view
    }

    public func updateUIView(_ uiView: UISeedPhrasesTextView, context _: Context) {
        let currentPhrases = uiView.getPhrases().joined(separator: " ")
        if currentPhrases != text.seedPhraseFormatted {
            uiView.replaceText(newText: text)
        }
        
        if uiView.isFirstResponder, !isFirstResponder {
            DispatchQueue.main.async { uiView.resignFirstResponder() }
        } else if !uiView.isFirstResponder, isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator($text, isFirstResponder: $isFirstResponder)
    }

    public class Coordinator: NSObject, UISeedPhraseTextViewDelegate {
        var text: Binding<String>
        var isFirstResponder: Binding<Bool>

        init(_ text: Binding<String>, isFirstResponder: Binding<Bool>) {
            self.text = text
            self.isFirstResponder = isFirstResponder
        }
        
        public func seedPhrasesTextView(_ textView: UISeedPhrasesTextView, didEnterPhrases phrases: String) {
            text.wrappedValue = phrases
        }
        
        public func seedPhrasesTextViewDidBeginEditing(_ textView: UISeedPhrasesTextView) {
            isFirstResponder.wrappedValue = true
        }
        
        public func seedPhrasesTextViewDidEndEditing(_ textView: UISeedPhrasesTextView) {
            isFirstResponder.wrappedValue = false
        }
    }
}
