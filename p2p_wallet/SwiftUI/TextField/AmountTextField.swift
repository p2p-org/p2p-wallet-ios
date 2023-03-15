//
//  AmountTextField.swift
//  p2p_wallet
//
//  Created by Ivan on 14.03.2023.
//

import Foundation
import UIKit
import SwiftUI
import KeyAppUI

struct AmountTextField: UIViewRepresentable {

    @Binding private var value: Double?
    @Binding private var isFirstResponder: Bool
    @Binding private var textColor: UIColor
    private let maxFractionDigits: Int
    private let decimalSeparator: String
    private var configuration = { (_: AmountUITextField) in }

    // MARK: - Init
    
    init(
        value: Binding<Double?>,
        isFirstResponder: Binding<Bool>,
        textColor: Binding<UIColor> = Binding.constant(Asset.Colors.night.color),
        maxFractionDigits: Int,
        decimalSeparator: String = ".",
        configuration: @escaping (AmountUITextField) -> Void = { _ in }
    ) {
        _value = value
        _isFirstResponder = isFirstResponder
        _textColor = textColor
        self.maxFractionDigits = maxFractionDigits
        self.decimalSeparator = decimalSeparator
        self.configuration = configuration
    }
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> AmountUITextField {
        let textField = AmountUITextField(value: $value, firstResponder: $isFirstResponder)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.decimalSeparator = decimalSeparator
        textField.maxFractionDigits = maxFractionDigits
        textField.textColor = textColor
        configuration(textField)
        return textField
    }

    func updateUIView(_ uiView: AmountUITextField, context _: Context) {
        if let value = value {
            if let text = uiView.text, let double = Double(text), double == value
            {
                
            } else {
                uiView.text = value.toString(
                    decimalSeparator: decimalSeparator,
                    maximumFractionDigits: maxFractionDigits
                )
            }
        } else {
            uiView.text = nil
        }
        
        if uiView.isFirstResponder, !isFirstResponder {
            DispatchQueue.main.async { uiView.resignFirstResponder() }
        } else if !uiView.isFirstResponder, isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        }
        
        configuration(uiView)
        uiView.textColor = textColor
    }
}

// MARK: - AmountUITextField

final class AmountUITextField: UITextField, UITextFieldDelegate {
    
    fileprivate var decimalSeparator = Locale.current.decimalSeparator ?? "."
    fileprivate var maxFractionDigits = 2
    var max: Double?
    
    var value: Binding<Double?>
    var firstResponder: Binding<Bool>
    
    // MARK: - Init

    convenience init(value: Binding<Double?>, firstResponder: Binding<Bool>) {
        self.init(frame: .zero)
        self.value = value
        self.firstResponder = firstResponder
    }

    override init(frame: CGRect) {
        self.value = .constant(nil)
        self.firstResponder = .constant(false)
        super.init(frame: frame)
        commonInit()
    }
    
    @available(*, unavailable,
    message: "Loading this view from a nib is unsupported in favor of initializer dependency injection."
    )
    required init?(coder: NSCoder) {
        fatalError("Loading this view from a nib is unsupported in favor of initializer dependency injection.")
    }
    
    // Private
    private func commonInit() {
        keyboardType = .decimalPad
        delegate = self
        addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
    }
    
    @objc private func textFieldEditingChanged() {
        text = text?.amountFormat(maxAfterComma: maxFractionDigits, decimalSeparator: decimalSeparator)
        value.wrappedValue = Double(text ?? "")
    }
    
    private func isNotMoreThanMax(text: String) -> Bool {
        guard
            let max = max,
            let number = Double(text)
        else { return true }

        return number <= max
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(_: UITextField) {
        firstResponder.wrappedValue = true
    }

    func textFieldDidEndEditing(_: UITextField) {
        firstResponder.wrappedValue = false
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        firstResponder.wrappedValue = false
        return true
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if let text = textField.text, let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            return isNotMoreThanMax(text: updatedText.amountFormat(
                maxAfterComma: maxFractionDigits,
                decimalSeparator: decimalSeparator
            ))
        }
        return true
    }
}

private extension Double {
    func toString(
        decimalSeparator: String,
        maximumFractionDigits: Int
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = decimalSeparator
        formatter.groupingSeparator = ""
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = 0
        return formatter.string(from: self as NSNumber) ?? "0"
    }
}
