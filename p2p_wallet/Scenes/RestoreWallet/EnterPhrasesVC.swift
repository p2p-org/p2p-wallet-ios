//
//  EnterPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2020.
//

import Foundation
import UITextView_Placeholder
import SubviewAttachingTextView

class EnterPhrasesVC: BaseVStackVC {
    override var padding: UIEdgeInsets {.init(all: 20)}
    
    lazy var textView: SubviewAttachingTextView = {
        let tv = SubviewAttachingTextView(forExpandable: ())
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 15)
        tv.typingAttributes = [.font: UIFont.systemFont(ofSize: 15)]
        tv.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
            .isActive = true
        tv.placeholder = L10n.enterSeedPhrasesInACorrectOrderToRecoverYourWallet
        tv.delegate = self
        tv.autocapitalizationType = .none
        tv.autocorrectionType = .no
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
    class Attachment: SubviewTextAttachment {
        var phrase: String?
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // if deleting
        if text.isEmpty { return true }
        
        // prevent dupplicated spaces
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            // prevent space at the begining
            if range.location == 0 {return false}
            // prevent 2 spaces next to each other
            else if textView.attributedText.attributedSubstring(from: NSRange(location: range.location - 1, length: 1)).string == " " {
                return false
            }
        }
        
        // ignore invalid characters
        let invalidCharactersSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz ").inverted
        
        if text.lowercased().rangeOfCharacter(from: invalidCharactersSet) == nil {
            // wrap phrase when found a space
            DispatchQueue.main.async {
                if text == " " || text.count > 1 {
                    self.wrapPhrase()
                }
            }
            return true
        }
        return false
    }
    
    private func wrapPhrase() {
        // get all phrases
        let phrases = textView.text.components(separatedBy: " ")
        
        // get length's difference after replacing text with attachment
        var lengthDiff = 0
        var selectedLocation = textView.selectedRange.location
        
        for phrase in phrases.map({$0.replacingOccurrences(of: "\u{fffc}", with: "")}).filter({!$0.isEmpty}) {
            let text = textView.text as NSString
            let range = text.range(of: phrase)
            
            // add attachment
            textView.textStorage.replaceCharacters(in: range, with: attachment(phrase: phrase))
            
            // diff of length, length become 1 when inserting attachment
            lengthDiff = 1 - phrase.count
            
            if selectedLocation > range.location {
                selectedLocation += lengthDiff
            }
        }
        // re-arrange attachment's order
        var count = 0
        textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textView.attributedText.length)) { (att, range, _) in
            if let att = att as? Attachment, let phrase = att.phrase {
                count += 1
                textView.textStorage.replaceCharacters(in: range, with: attachment(phrase: phrase, index: count))
            }
        }
        
        // recalculate selected range
        DispatchQueue.main.async {
            self.textView.selectedRange = NSRange(location: selectedLocation + 1, length: 0)
        }
    }
    
    fileprivate func attachment(phrase: String, index: Int? = nil) -> NSAttributedString {
        // replace phrase's range by attachment that is a uilabel
        let label = UILabel(text: (index != nil ? "\(index!). " : "" ) + phrase, textSize: 15)
            .padding(.init(x: 10, y: 6), backgroundColor: .textWhite, cornerRadius: 5)
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.textBlack.cgColor
        label.translatesAutoresizingMaskIntoConstraints = true
        
        // replace text by attachment
        let attachment = Attachment(view: label)
        attachment.phrase = phrase
        let attrString = NSMutableAttributedString(attachment: attachment)
        attrString.addAttributes(textView.typingAttributes, range: NSRange(location: 0, length: attrString.length))
        return attrString
    }
    
    fileprivate func getPhrasesInTextView() -> [String] {
        var phrases = [String]()
        textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textView.attributedText.length)) { (att, _, _) in
            if let att = att as? Attachment, let phrase = att.phrase {
                phrases.append(phrase)
            }
        }
        return phrases
    }
}
