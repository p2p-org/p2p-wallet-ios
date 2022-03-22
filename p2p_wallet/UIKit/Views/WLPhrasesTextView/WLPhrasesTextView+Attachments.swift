//
//  WLPhrasesTextView+Attachments.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/03/2021.
//

import Foundation
import SubviewAttachingTextView

extension WLPhrasesTextView {
    // MARK: - Attachment types

    class Attachment: SubviewTextAttachment {
        override func attachmentBounds(
            for textContainer: NSTextContainer?,
            proposedLineFragment lineFrag: CGRect,
            glyphPosition position: CGPoint,
            characterIndex charIndex: Int
        ) -> CGRect {
            var bounds = super.attachmentBounds(
                for: textContainer,
                proposedLineFragment: lineFrag,
                glyphPosition: position,
                characterIndex: charIndex
            )
            bounds.origin.y -= 15
            return bounds
        }
    }

    class PhraseAttachment: Attachment {
        var phrase: String?
    }

    class PlaceholderAttachment: Attachment {}

    // MARK: - Methods

    func attachment(phrase: String, index: Int? = nil) -> NSAttributedString? {
        // ignore invalid characters
        let invalidCharactersSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz").inverted

        let phrase = phrase.lowercased().components(separatedBy: invalidCharactersSet).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)

        if phrase.isEmpty {
            return nil
        }

        // replace phrase's range by attachment that is a uilabel
        let label = { () -> UILabel in
            let label = UILabel(textColor: .textBlack)
            label.attributedText = NSMutableAttributedString()
                .text("\(index != nil ? "\(index!)" : ""). ", size: 15, weight: .semibold, color: .iconSecondary)
                .text("\(phrase)", size: 15, weight: .semibold)
            return label
        }()
            .padding(.init(x: 12, y: 12), backgroundColor: .tagBackground, cornerRadius: 5)
        label.border(width: 1, color: .tagBorder)
        label.translatesAutoresizingMaskIntoConstraints = true
        label.isUserInteractionEnabled = true

        // replace text by attachment
        let attachment = PhraseAttachment(view: label)
        attachment.phrase = phrase
        let attrString = NSMutableAttributedString(attachment: attachment)
        attrString.addAttributes(typingAttributes, range: NSRange(location: 0, length: attrString.length))
        return attrString
    }

    func placeholderAttachment(at index: Int) -> NSMutableAttributedString {
        let label = UILabel(text: "\(index + 1). ", weight: .semibold, textColor: .a3a5baStatic)
            .padding(.init(top: 12, left: 12, bottom: 12, right: 0))
        label.translatesAutoresizingMaskIntoConstraints = true
        label.isUserInteractionEnabled = true

        // replace text by attachment
        let attachment = PlaceholderAttachment(view: label)
        let attrString = NSMutableAttributedString(attachment: attachment)
        attrString.addAttributes(typingAttributes, range: NSRange(location: 0, length: attrString.length))
        return attrString
    }

    // MARK: - Helpers

    func addPlaceholderAttachment(at index: Int) {
        textStorage.replaceCharacters(in: selectedRange, with: placeholderAttachment(at: phraseIndex(at: index)))
    }

    func phraseIndex(at location: Int) -> Int {
        var count = 0
        attributedText
            .enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedText.length)) { att, range, _ in
                if range.location > location { return }
                if att is PhraseAttachment {
                    count += 1
                }
            }
        return count
    }

    func removeAllPlaceholderAttachment() {
        var lengthDiff = 0
        textStorage
            .enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedText.length)) { att, range, _ in
                if att is PlaceholderAttachment {
                    var range = range
                    range.location += lengthDiff
                    textStorage.replaceCharacters(in: range, with: "")
                    lengthDiff -= 1
                }
            }
    }
}

extension WLPhrasesTextView {
    func isPlaceholder(at range: NSRange) -> Bool {
        if range.length > 1 { return false }
        var flag = false
        textStorage.enumerateAttribute(.attachment, in: range, options: []) { value, _, _ in
            if value is PlaceholderAttachment {
                flag = true
                return
            } else {
                return
            }
        }
        return flag
    }
}
