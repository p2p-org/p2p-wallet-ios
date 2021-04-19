//
//  WLPhrasesTextView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/03/2021.
//

import Foundation
import SubviewAttachingTextView

protocol WLPhrasesTextViewDelegate: class {
    func wlPhrasesTextViewDidBeginEditing(_ textView: WLPhrasesTextView)
}

class WLPhrasesTextView: SubviewAttachingTextView {
    // MARK: - Properties
    let defaultFont = UIFont.systemFont(ofSize: 15)
    private var shouldWrapPhrases = false
    private var shouldRearrange = false
    
    weak var forwardedDelegate: WLPhrasesTextViewDelegate?
    
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
        tintColor = .textBlack
        
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
        
        // add first placeholder
//        addPlaceholderAttachment(at: 0)
//        selectedRange = NSRange(location: 1, length: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func paste(_ sender: Any?) {
        super.paste(sender)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.selectedRange.location = self?.attributedText.length ?? 0
        }
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
    
    func clear() {
        text = nil
//        addPlaceholderAttachment(at: 0)
//        selectedRange = NSRange(location: 1, length: 0)
    }
    
    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        let beginning = self.beginningOfDocument
        let end = self.position(from: beginning, offset: attributedText.length)
        return end
    }
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        var original = super.caretRect(for: position)
        let height: CGFloat = 20
        original.origin.y += (original.size.height - 20) / 2
        original.size.height = height
        return original
    }
}

extension WLPhrasesTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        forwardedDelegate?.wlPhrasesTextViewDidBeginEditing(self)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if shouldWrapPhrases {
            wrapPhrase()
        }
        
        if shouldRearrange {
            rearrangeAttachments()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // disable
        shouldWrapPhrases = false
        shouldRearrange = false
        
        // if deleting
        if text.isEmpty {
            // check if remove all character
            let newText = NSMutableAttributedString(attributedString: attributedText)
            newText.replaceCharacters(in: range, with: text)
            if newText.length == 0 {
                textStorage.replaceCharacters(in: range, with: text)
                addPlaceholderAttachment(at: 0)
                selectedRange = NSRange(location: 1, length: 0)
                return false
            }
            
            // remove others
            self.shouldRearrange = true
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
                removeAllPlaceholderAttachment()
                shouldWrapPhrases = true
                shouldRearrange = true
            }
            return true
        }
        return false
    }
    
    func wrapPhrase(addingPlaceholderAttachment: Bool = true) {
        // get all phrases
        let phrases = text.components(separatedBy: " ")
        
        // get length's difference after replacing text with attachment
        var lengthDiff = 0
        var selectedLocation = selectedRange.location
        
        for phrase in phrases.map({$0.replacingOccurrences(of: "\u{fffc}", with: "")}).filter({!$0.isEmpty}) {
            let text = self.text as NSString
            let range = text.range(of: phrase)
            
            // add attachment
            let aStr = NSMutableAttributedString()
            aStr.append(attachment(phrase: phrase))
            textStorage.replaceCharacters(in: range, with: aStr)
            
            // diff of length, length become 1 when inserting attachment
            lengthDiff = aStr.length - phrase.count
            
            if selectedLocation > range.location {
                selectedLocation += lengthDiff
            }
        }
        
        shouldWrapPhrases = false
        
        // recalculate selected range
        if addingPlaceholderAttachment {
            addPlaceholderAttachment(at: selectedLocation)
            selectedRange = NSRange(location: selectedLocation + 1, length: 0)
        }
    }
    
    fileprivate func rearrangeAttachments() {
        var count = 0
        attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedText.length)) { (att, range, _) in
            if let att = att as? PhraseAttachment, let phrase = att.phrase {
                count += 1
                textStorage.replaceCharacters(in: range, with: attachment(phrase: phrase, index: count))
            }
            
            if att is PlaceholderAttachment {
                count += 1
            }
        }
        shouldRearrange = false
    }
}
