//
//  WLView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class WLButton: UIButton {
    enum StepButtonType {
        case black, sub, blue, gray
        var backgroundColor: UIColor {
            switch self {
            case .black:
                return .black
            case .sub:
                return .h202020
            case .blue:
                return .h5887ff
            case .gray:
                return .f6f6f8
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .gray:
                return .black
            case .sub, .blue, .black:
                return .white
            }
        }
    }
    
    static func stepButton(type: StepButtonType, label: String?) -> WLButton {
        WLButton(height: 56, backgroundColor: type.backgroundColor, cornerRadius: 15, label: label, labelFont: .systemFont(ofSize: 17, weight: .medium), textColor: type.textColor)
    }
    
    override var isEnabled: Bool {
        didSet {isEnabled ? (alpha = 1) : (alpha = 0.5)}
    }
}
