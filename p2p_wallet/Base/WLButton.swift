//
//  WLView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class WLButton: UIButton {
    enum StepButtonType {
        case main, sub
    }
    
    static func stepButton(type: StepButtonType, label: String?) -> WLButton {
        WLButton(height: 56, backgroundColor: type == .main ? .textBlack : .buttonSub, cornerRadius: 15, label: label, labelFont: .systemFont(ofSize: 17, weight: .medium), textColor: type == .main ? .textWhite : .textBlack)
    }
    
    override var isEnabled: Bool {
        didSet {isEnabled ? (alpha = 1) : (alpha = 0.5)}
    }
}
