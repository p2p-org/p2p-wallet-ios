//
//  WLPhrasesTextView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/03/2021.
//

import Foundation
import SubviewAttachingTextView

class WLPhrasesTextView: SubviewAttachingTextView {
    // MARK: - Properties
    let defaultFont = UIFont.systemFont(ofSize: 15)
    private var shouldWrapPhrases = false
    private var shouldRearrange = false
    
    override weak var delegate: UITextViewDelegate? {
        didSet {
            if !(delegate is Self) {
                fatalError("Use phrases text view delegate instead")
            }
        }
    }
    
    // MARK: - Initializers
    init() {
        super.init(frame: .zero, textContainer: nil)
        configureForAutoLayout()
        isScrollEnabled = false
        
        backgroundColor = .clear
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        
        typingAttributes = [
            .font: defaultFont,
            .paragraphStyle: paragraphStyle
        ]
        
        heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
            .isActive = true
        placeholder = L10n.enterSeedPhrasesInACorrectOrderToRecoverYourWallet
        delegate = self
        autocapitalizationType = .none
        autocorrectionType = .no
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    func getPhrases() -> [String] {
        var phrases = [String]()
        attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedText.length)) { (att, _, _) in
            if let att = att as? PhraseAttachment, let phrase = att.phrase {
                phrases.append(phrase)
            }
        }
        return phrases
    }
}

extension WLPhrasesTextView: UITextViewDelegate {
    class Attachment: SubviewTextAttachment {
        override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
            var bounds = super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
            bounds.origin.y -= 15
            return bounds
        }
    }
    
    class PhraseAttachment: Attachment {
        var phrase: String?
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if shouldWrapPhrases {
            wrapPhrase()
        }
        
        if shouldRearrange {
            rearrangeTextView()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // if deleting
        if text.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                self?.rearrangeTextView()
            }
            return true
        }
        
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
            if text.contains(" ") {
                shouldWrapPhrases = true
                shouldRearrange = true
            } else {
                shouldWrapPhrases = false
                shouldRearrange = false
            }
            return true
        }
        return false
    }
    
    func wrapPhrase() {
        // get all phrases
        let phrases = text.components(separatedBy: " ")
        
        for phrase in phrases.map({$0.replacingOccurrences(of: "\u{fffc}", with: "")}).filter({!$0.isEmpty}) {
            let text = self.text as NSString
            let range = text.range(of: phrase)
            
            // add attachment
            let aStr = NSMutableAttributedString()
            aStr.append(attachment(phrase: phrase))
            textStorage.replaceCharacters(in: range, with: aStr)
        }
    }
    
    fileprivate func rearrangeTextView() {
        var count = 0
        attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedText.length)) { (att, range, _) in
            if let att = att as? PhraseAttachment, let phrase = att.phrase {
                count += 1
                textStorage.replaceCharacters(in: range, with: attachment(phrase: phrase, index: count))
            }
        }
    }
    
    fileprivate func attachment(phrase: String, index: Int? = nil) -> NSAttributedString {
        let phrase = phrase.lowercased()
        // replace phrase's range by attachment that is a uilabel
        let label = { () -> UILabel in
            let label = UILabel(textColor: .textBlack)
            label.attributedText = NSMutableAttributedString()
                .text("\(index != nil ? "\(index!)": ""). ", size: 15, color: .a3a5ba)
                .text("\(phrase)", size: 15)
            return label
        }()
            .padding(.init(x: 12, y: 12), backgroundColor: .textWhite, cornerRadius: 5)
        label.border(width: 1, color: UIColor.a3a5ba.withAlphaComponent(0.5))
        label.translatesAutoresizingMaskIntoConstraints = true
        
        // replace text by attachment
        let attachment = PhraseAttachment(view: label)
        attachment.phrase = phrase
        let attrString = NSMutableAttributedString(attachment: attachment)
        attrString.addAttributes(typingAttributes, range: NSRange(location: 0, length: attrString.length))
        return attrString
    }
}
