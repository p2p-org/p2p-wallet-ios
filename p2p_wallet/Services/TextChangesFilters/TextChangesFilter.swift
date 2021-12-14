//
//  TextChangesFilter.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.12.2021.
//

import UIKit

protocol ContainsText: AnyObject {
    func getText() -> String?
}

extension UITextView: ContainsText {
    func getText() -> String? {
        text
    }
}

extension UITextField: ContainsText {
    func getText() -> String? {
        text
    }
}

protocol TextChangesFilter: AnyObject {
    func isValid(textContainer: ContainsText, string: String, range: NSRange) -> Bool
    func isValid(string: String) -> Bool
}
