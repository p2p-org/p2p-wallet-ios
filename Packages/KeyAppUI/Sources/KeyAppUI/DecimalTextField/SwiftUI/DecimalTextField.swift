//
//  DecimalTextField.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2022.
//

import Foundation
import UIKit
import SwiftUI

/// TextField that allows only decimal number
public struct DecimalTextField: UIViewRepresentable {
    
    // MARK: - Properties

    /// Detect if decimal text field is first responder
    @Binding private var isFirstResponder: Bool
    
    /// Value of current text field
    @Binding private var value: Double?

    /// Color of text
    @Binding private var textColor: UIColor

    /// Additional configuration
    private var configuration = { (_: UIDecimalTextField) in }

    public init(
        value: Binding<Double?>,
        isFirstResponder: Binding<Bool>,
        textColor: Binding<UIColor> = Binding.constant(Asset.Colors.night.color),
        configuration: @escaping (UIDecimalTextField) -> Void = { _ in }
    ) {
        self.configuration = configuration
        _value = value
        _isFirstResponder = isFirstResponder
        _textColor = textColor
    }

    public func makeUIView(context: Context) -> UIDecimalTextField {
        let view = UIDecimalTextField()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.forwardedDelegate = context.coordinator
        view.textColor = textColor
        configuration(view)
        return view
    }

    public func updateUIView(_ uiView: UIDecimalTextField, context _: Context) {
        if let value = value {
            if let text = uiView.text,
               let double = Double(text),
               double == value
            {
                
            } else {
                uiView.text = value.toString(decimalSeparator: uiView.decimalSeparator, maximumFractionDigits: uiView.maximumFractionDigits ?? 9)
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

    public func makeCoordinator() -> Coordinator {
        Coordinator($value, isFirstResponder: $isFirstResponder)
    }

    public class Coordinator: NSObject, UIDecimalTextFieldDelegate {
        var value: Binding<Double?>
        var isFirstResponder: Binding<Bool>

        init(_ value: Binding<Double?>, isFirstResponder: Binding<Bool>) {
            self.value = value
            self.isFirstResponder = isFirstResponder
        }
        
        public func decimalTextFieldDidReceiveValue(_ decimalTextField: UIDecimalTextField, value: Double?) {
            self.value.wrappedValue = value
        }
        
        public func textFieldDidBeginEditing(_: UITextField) {
            DispatchQueue.main.async { [weak self] in
                self?.isFirstResponder.wrappedValue = true
            }
        }

        public func textFieldDidEndEditing(_: UITextField) {
            DispatchQueue.main.async { [weak self] in
                self?.isFirstResponder.wrappedValue = false
            }
        }
        
        public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            // TODO: - Why textFieldDidEndEditing not called??
            DispatchQueue.main.async { [weak self] in
                self?.isFirstResponder.wrappedValue = false
            }
            return true
        }
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
