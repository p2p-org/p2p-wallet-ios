//
//  PercentSuffixTextField.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/02/2021.
//

import Foundation
import KeyAppUI

final class PercentSuffixTextField: BEDecimalTextField, UITextFieldDelegate {
    lazy var percentLabel = UILabel(text: "%", font: font, textColor: Asset.Colors.mountain.color)
    var percentLabelLeftConstraint: NSLayoutConstraint!
    
    override func commonInit() {
        super.commonInit()
        addSubview(percentLabel)
        percentLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        percentLabelLeftConstraint = percentLabel.autoPinEdge(
            toSuperviewEdge: .leading,
            withInset: leftView?.frame.size.width ?? 0
        )
        delegate = self
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
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if (textField as? BEDecimalTextField)?.shouldChangeCharactersInRange(range, replacementString: string) == true {
            return true
        } else {
            return false
        }
    }
}
