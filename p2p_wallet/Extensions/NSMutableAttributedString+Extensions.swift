//
//  NSMutableAttributedString+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    @discardableResult
    func text(_ text: String, size: CGFloat = 15, weight: UIFont.Weight = .regular, color: UIColor = .textBlack, baselineOffset: CGFloat? = nil) -> NSMutableAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
        if let baselineOffset = baselineOffset {
            attrs[.baselineOffset] = baselineOffset
        }
        let normal = NSAttributedString(string: text, attributes: attrs)
        append(normal)
        return self
    }
    
    @discardableResult
    func withParagraphStyle(lineSpacing: CGFloat, alignment: NSTextAlignment? = nil) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        if let alignment = alignment {
            paragraphStyle.alignment = alignment
        }
        addAttributes([.paragraphStyle: paragraphStyle], range: .init(location: 0, length: length))
        return self
    }
}

extension NSAttributedString {
    static func slippageAttributedText(
        slippage: Double
    ) -> NSAttributedString {
        if slippage > .maxSlippage {
            return NSMutableAttributedString()
                .text((slippage * 100).toString(maximumFractionDigits: 9) + "%", weight: .medium)
                .text(" ", weight: .medium)
                .text(L10n.slippageExceedsMaximum, weight: .medium, color: .red)
        } else if slippage > .frontrunSlippage && slippage <= .maxSlippage {
            return NSMutableAttributedString()
                .text((slippage * 100).toString(maximumFractionDigits: 9) + "%", weight: .medium)
                .text(" ", weight: .medium)
                .text(L10n.yourTransactionMayBeFrontrun, weight: .medium, color: .attentionGreen)
        } else {
            return NSMutableAttributedString()
                .text((slippage * 100).toString(maximumFractionDigits: 9) + "%", weight: .medium)
        }
    }
}
