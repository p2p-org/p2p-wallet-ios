//
//  EnterPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2020.
//

import Foundation
import UITextView_Placeholder

class EnterPhrasesVC: BaseVStackVC {
    override var padding: UIEdgeInsets {.init(all: 20)}
    
    lazy var textView: UITextView = {
        let tv = UITextView(forExpandable: ())
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 15)
        tv.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
            .isActive = true
        tv.placeholder = L10n.enterSeedPhrasesInACorrectOrderToRecoverYourWallet
        tv.delegate = self
        tv.autocapitalizationType = .none
        return tv
    }()
    
    override func setUp() {
        super.setUp()
        title = L10n.enterSecurityKeys
        stackView.addArrangedSubview(
            textView.padding(.init(all: 16), backgroundColor: .lightGrayBackground, cornerRadius: 16)
        )
    }
}

extension EnterPhrasesVC: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // if deleting
        if text.isEmpty { return true }
        
        let invalidCharactersSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz ").inverted
        
        if text.lowercased().rangeOfCharacter(from: invalidCharactersSet) == nil {
            // force lowercase
            
            // get the current text, or use an empty string if that failed
            let currentText = textView.text ?? ""

            // attempt to read the range they are trying to change, or exit if we can't
            guard let stringRange = Range(range, in: currentText) else { return false }

            // add their new text to the existing text
            var updatedText = currentText.replacingCharacters(in: stringRange, with: text.lowercased())
            
            updatedText = updatedText.replacingOccurrences(of: " +", with: " ", options: String.CompareOptions.regularExpression, range: nil)
            
            // force lowercase
            textView.text = updatedText
            
            wrapPhrase()
        }
        return false
    }
    
    private func wrapPhrase() {
        // get all phrases
        let phrases = textView.text.components(separatedBy: " ")
        
        // find phrases ranges
        
        // replace phrases ranges by attachments that are uilabel
        
    }
}
