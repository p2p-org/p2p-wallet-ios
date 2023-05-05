//
//  UIDecimalTextField.swift
//  BEPureLayout
//
//  Created by Chung Tran on 20/11/2020.
//

import Foundation
import UIKit

public protocol UIDecimalTextFieldDelegate: UITextFieldDelegate {
    func decimalTextFieldDidReceiveValue(_ decimalTextField: UIDecimalTextField, value: Double?)
}

/// UITextField that allows only decimal number
open class UIDecimalTextField: UITextField, UITextFieldDelegate {
    
    // MARK: - Properties
    
    /// Symbol that define decimalSeparator, can be "," or "." depends on location
    public var decimalSeparator: String = Locale.current.decimalSeparator ?? "."
    
    /// Maximum fraction digits (number of digits after decimalSeparator
    public var maximumFractionDigits: Int?
    
    /// Max value
    public var max: Double?
    
    /// Disabled default delegate
    open override var delegate: UITextFieldDelegate? {
        didSet {
            if (delegate as? UIDecimalTextField) != self {fatalError("Use forwardedDelegate instead")}
        }
    }
    
    /// Forwarded delegate
    public weak var forwardedDelegate: UIDecimalTextFieldDelegate?
    
    // MARK: - Initializer

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    @available(*, unavailable,
    message: "Loading this view from a nib is unsupported in favor of initializer dependency injection."
    )
    public required init?(coder: NSCoder) {
        fatalError("Loading this view from a nib is unsupported in favor of initializer dependency injection.")
    }
    
    open func commonInit() {
        keyboardType = .decimalPad
        delegate = self
    }
    
    // MARK: - Delegation
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        forwardedDelegate?.textFieldShouldBeginEditing?(textField) ?? true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        forwardedDelegate?.textFieldDidBeginEditing?(textField)
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        forwardedDelegate?.textFieldShouldEndEditing?(textField) ?? true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        forwardedDelegate?.textFieldDidEndEditing?(textField)
    }

    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        forwardedDelegate?.textFieldDidEndEditing?(textField, reason: reason)
    }

    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // fix conflict in decimal separator
        let string = string
            .replacingOccurrences(of: ",", with: decimalSeparator)
            .replacingOccurrences(of: ".", with: decimalSeparator)
        
        // if input comma (or dot)
        if text?.isEmpty == true, string == decimalSeparator {
            text = "0\(decimalSeparator)"
            forwardedDelegate?.decimalTextFieldDidReceiveValue(self, value: 0)
            return false
        }
        
        // if deleting
        if string.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [unowned self] in
                forwardedDelegate?.decimalTextFieldDidReceiveValue(self, value: text?.toDouble(decimalSeparator: decimalSeparator))
            }
            
            return true
        }
        
        // get the current text, or use an empty string if that failed
        let currentText = text ?? ""

        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }

        // add their new text to the existing text
        var updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // check if newText is a Number
        let formatter = NumberFormatter()
        let isANumber = formatter.number(from: updatedText.replacingOccurrences(of: decimalSeparator, with: Locale.current.decimalSeparator ?? ".")) != nil
        
        if updatedText.starts(with: "0") && !updatedText.starts(with: "0\(decimalSeparator)") {
            updatedText = updatedText.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
            if updatedText.isEmpty {
                updatedText = "0"
            }
            text = updatedText
            forwardedDelegate?.decimalTextFieldDidReceiveValue(self, value: updatedText.toDouble(decimalSeparator: decimalSeparator))
            return false
        }

        let shouldChange = isANumber
            && textHasRightMaximumFractionDigits(text: updatedText, separator: decimalSeparator)
            && isNotMoreThanMax(text: updatedText)
        
        if shouldChange {
            text = updatedText
            forwardedDelegate?.decimalTextFieldDidReceiveValue(self, value: updatedText.toDouble(decimalSeparator: decimalSeparator))
            return false
        }
        
        return false
    }

    public func textFieldDidChangeSelection(_ textField: UITextField) {
        forwardedDelegate?.textFieldDidChangeSelection?(textField)
    }

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        forwardedDelegate?.textFieldShouldClear?(textField) ?? true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        forwardedDelegate?.textFieldShouldReturn?(textField) ?? true
    }
    
    @available(iOS 16.0, *)
    public func textField(_ textField: UITextField, editMenuForCharactersIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        forwardedDelegate?.textField?(textField, editMenuForCharactersIn: range, suggestedActions: suggestedActions)
    }
    
    @available(iOS 16.0, *)
    public func textField(_ textField: UITextField, willPresentEditMenuWith animator: UIEditMenuInteractionAnimating) {
        forwardedDelegate?.textField?(textField, willPresentEditMenuWith: animator)
    }
    
    @available(iOS 16.0, *)
    public func textField(_ textField: UITextField, willDismissEditMenuWith animator: UIEditMenuInteractionAnimating) {
        forwardedDelegate?.textField?(textField, willDismissEditMenuWith: animator)
    }
    
    
    // MARK: - Helpers

    private func textHasRightMaximumFractionDigits(text: String, separator: String) -> Bool {
        guard
            let maximumFractionDigits = maximumFractionDigits,
            let indexOfSeparator = text.firstIndex (of: Character(separator))
        else {
            return true
        }

        return text[indexOfSeparator...].count - 1 <= maximumFractionDigits
    }

    private func isNotMoreThanMax(text: String) -> Bool {
        guard
            let max = max,
            let number = text.toDouble(decimalSeparator: decimalSeparator)
        else {
            return true
        }

        return number <= max
    }
}

private extension String {
    func toDouble(decimalSeparator: String) -> Double? {
        guard let number = NumberFormatter().number(from: replacingOccurrences(of: decimalSeparator, with: Locale.current.decimalSeparator ?? "."))?.doubleValue
        else {
            return nil
        }
        return number
    }
}
