//
//  WLPhrasesTextView+Attachments.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/03/2021.
//

import Foundation
import SubviewAttachingTextView

extension WLPhrasesTextView {
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
}
