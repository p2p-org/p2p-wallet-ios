//
//  TextFieldWithSuffix.swift
//  p2p_wallet
//
//  Created by Ivan on 01.03.2023.
//

import SwiftUI
import KeyAppUI

struct TextFieldWithSuffix: UIViewRepresentable {
    @Binding var text: String
    @Binding var textColor: UIColor
    @Binding var becomeFirstResponder: Bool
    
    private let title: String?

    let textField = PercentSuffixTextField()

    init(
        title: String?,
        text: Binding<String>,
        textColor: Binding<UIColor>,
        becomeFirstResponder: Binding<Bool>
    ) {
        self.title = title
        _text = text
        _textColor = textColor
        _becomeFirstResponder = becomeFirstResponder
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, textField: textField)
    }

    func makeUIView(context: Context) -> UITextField {
        textField.placeholder = title
        textField.keyboardType = .decimalPad
        textField.font = .font(of: .text3)
        textField.countAfterDecimalPoint = 2
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if becomeFirstResponder {
            DispatchQueue.main.async {
                self.textField.becomeFirstResponder()
                self.becomeFirstResponder = false
            }
        }
        uiView.text = text
        uiView.textColor = textColor
    }
}

extension TextFieldWithSuffix {
    final class Coordinator: NSObject {
        @Binding private var text: String
        private let textField: UITextField
        
        init(text: Binding<String>, textField: UITextField) {
            _text = text
            self.textField = textField
            super.init()
            textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        }
        
        @objc func textFieldDidChange() {
            text = textField.text ?? ""
        }
    }
}
