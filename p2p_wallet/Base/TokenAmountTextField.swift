//
//  TokenAmountTextField.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation

class TokenAmountTextField: BEDecimalTextField {
    var wallet: Wallet?
    var value: Double {
        text.map {$0.double ?? 0} ?? 0
    }
    
    override func shouldChangeCharactersInRange(_ range: NSRange, replacementString string: String) -> Bool {
        // get the current text, or use an empty string if that failed
        let currentText = text ?? ""
        
        guard super.shouldChangeCharactersInRange(range, replacementString: string),
              let stringRange = Range(range, in: currentText)
        else {
            return false
        }
        // add their new text to the existing text
        var updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        if let dotIndex = updatedText.firstIndex(of: Locale.current.decimalSeparator?.first ?? ".") {
            let offset = updatedText.distance(from: dotIndex, to: updatedText.endIndex) - 1
            let decimals = wallet?.decimals ?? 9
            if offset > decimals {
                let endIndex = updatedText.index(dotIndex, offsetBy: decimals)
                updatedText = String(updatedText[updatedText.startIndex...endIndex])
                text = updatedText
                return false
            }
        }
        
        return true
    }
}
