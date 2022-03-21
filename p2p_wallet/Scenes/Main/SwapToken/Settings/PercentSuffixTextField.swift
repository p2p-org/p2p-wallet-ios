//
//  PercentSuffixTextField.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/02/2021.
//

import Foundation

class PercentSuffixTextField: BEDecimalTextField {
    lazy var percentLabel = UILabel(text: "%", font: font, textColor: textColor)
    var percentLabelLeftConstraint: NSLayoutConstraint!

    override func commonInit() {
        super.commonInit()
        addSubview(percentLabel)
        percentLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        percentLabelLeftConstraint = percentLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: leftView?.frame.size.width ?? 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let leftViewWidth = leftView?.frame.size.width ?? 0
        let textWidth = text?.size(withAttributes: [.font: font!]).width ?? 0
        let paddingX = leftViewWidth + textWidth
        if percentLabelLeftConstraint.constant != paddingX {
            percentLabelLeftConstraint.constant = paddingX
        }
    }
}
