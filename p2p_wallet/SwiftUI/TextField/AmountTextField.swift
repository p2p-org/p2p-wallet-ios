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
    @Binding private var maxFractionDigits: Int
    @Binding private var maxValue: Double?
    private let decimalSeparator: String
    private var configuration = { (_: AmountUITextField) in }

    // MARK: - Init
    
    init(
        value: Binding<Double?>,
        isFirstResponder: Binding<Bool>,
        textColor: Binding<UIColor> = Binding.constant(Asset.Colors.night.color),
        maxFractionDigits: Binding<Int>,
        maxValue: Binding<Double?> = .constant(nil),
        decimalSeparator: String = ".",
        configuration: @escaping (AmountUITextField) -> Void = { _ in }
    ) {
        _value = value
        _isFirstResponder = isFirstResponder
        _textColor = textColor
        _maxFractionDigits = maxFractionDigits
        _maxValue = maxValue
        self.decimalSeparator = decimalSeparator
        self.configuration = configuration
    }
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> AmountUITextField {
        let textField = AmountUITextField(
            value: $value,
            firstResponder: $isFirstResponder,
            maxFractionDigits: $maxFractionDigits,
            maxValue: $maxValue
        )
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.decimalSeparator = decimalSeparator
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
    fileprivate var value: Binding<Double?>
    fileprivate var firstResponder: Binding<Bool>
    fileprivate var maxFractionDigits: Binding<Int>
    fileprivate var maxValue: Binding<Double?>
    
    // MARK: - Init

    convenience init(
        value: Binding<Double?>,
        firstResponder: Binding<Bool>,
        maxFractionDigits: Binding<Int>,
        maxValue: Binding<Double?>
    ) {
        self.init(frame: .zero)
        self.value = value
        self.firstResponder = firstResponder
        self.maxFractionDigits = maxFractionDigits
        self.maxValue = maxValue
    }

    override init(frame: CGRect) {
        self.value = .constant(nil)
        self.firstResponder = .constant(false)
        self.maxFractionDigits = .constant(2)
        self.maxValue = .constant(nil)
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
        text = text?.amountFormat(
            maxAfterComma: maxFractionDigits.wrappedValue,
            decimalSeparator: decimalSeparator
        )
        value.wrappedValue = Double(text ?? "")
    }
    
    private func isNotMoreThanMax(text: String) -> Bool {
        guard
            let max = maxValue.wrappedValue,
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
        guard let text = textField.text, let textRange = Range(range, in: text) else { return true }

        let updatedText = text
            .replacingCharacters(in: textRange, with: string)
            .replacingOccurrences(of: decimalSeparator == "." ? "," : ".", with: decimalSeparator)
        if (updatedText.components(separatedBy: decimalSeparator).count - 1) > 1 {
            return false
        }
        if updatedText.components(separatedBy: decimalSeparator).last?.count ?? 0 > maxFractionDigits.wrappedValue {
            return false
        }
        return isNotMoreThanMax(text: updatedText.amountFormat(
            maxAfterComma: maxFractionDigits.wrappedValue,
            decimalSeparator: decimalSeparator
        ))
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
