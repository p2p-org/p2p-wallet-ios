//
//  DecimalTextField.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2022.
//

import Foundation
import UIKit
import SwiftUI
import BEPureLayout
import KeyAppUI

struct DecimalTextField: UIViewRepresentable {
    @Binding private var isFirstResponder: Bool
    @Binding private var value: Double?
    @Binding private var textColor: UIColor
    private var configuration = { (_: BEDecimalTextField) in }

    init(
        value: Binding<Double?>,
        isFirstResponder: Binding<Bool>,
        textColor: Binding<UIColor> = Binding.constant(Asset.Colors.night.color),
        configuration: @escaping (BEDecimalTextField) -> Void = { _ in }
    ) {
        self.configuration = configuration
        _value = value
        _textColor = textColor
        _isFirstResponder = isFirstResponder
    }

    func makeUIView(context: Context) -> BEDecimalTextField {
        let view = BEDecimalTextField()
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

    func updateUIView(_ uiView: BEDecimalTextField, context _: Context) {
        if let value = value {
            if let text = uiView.text,
               let double = Double(text),
               double == value
            {
                
            } else {
                uiView.text = value.toString(maximumFractionDigits: 9)
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

    func makeCoordinator() -> Coordinator {
        Coordinator($value, isFirstResponder: $isFirstResponder)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var value: Binding<Double?>
        var isFirstResponder: Binding<Bool>

        init(_ value: Binding<Double?>, isFirstResponder: Binding<Bool>) {
            self.value = value
            self.isFirstResponder = isFirstResponder
        }

        @objc func textViewDidChange(_ textField: UITextField) {
            if let text = textField.text,
               let double = Double(text)
            {
                value.wrappedValue = double
            } else {
                value.wrappedValue = nil
            }
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
            (textField as! BEDecimalTextField).shouldChangeCharactersInRange(range, replacementString: string)
        }
    }
}
