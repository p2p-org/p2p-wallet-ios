//
//  WLView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class WLButton: UIButton {
    enum StepButtonType {
        case main, sub, blue
        var backgroundColor: UIColor {
            switch self {
            case .main:
                return .textBlack
            case .sub:
                return .h202020
            case .blue:
                return .h5887ff
            }
        }
    }
    
    static func stepButton(type: StepButtonType, label: String?) -> WLButton {
        return WLButton(height: 56, backgroundColor: type.backgroundColor, cornerRadius: 15, label: label, labelFont: .systemFont(ofSize: 17, weight: .medium), textColor: .white)
    }
    
    override var isEnabled: Bool {
        didSet {isEnabled ? (alpha = 1) : (alpha = 0.5)}
    }
}
