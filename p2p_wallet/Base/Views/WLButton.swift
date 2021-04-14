//
//  WLView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class WLButton: UIButton {
    enum StepButtonType: Equatable {
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
        
        var disabledColor: UIColor? {
            switch self {
            case .blue:
                return .a3a5baStatic
            default:
                return nil
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
    
    static func stepButton(type: StepButtonType, label: String?, labelFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .semibold)) -> WLButton {
        let button = WLButton(height: 56, backgroundColor: type.backgroundColor, cornerRadius: 15, label: label, labelFont: labelFont, textColor: type.textColor)
        button.enabledColor = type.backgroundColor
        button.disabledColor = type.disabledColor
        return button
    }
    
    static func stepButton(enabledColor: UIColor, disabledColor: UIColor? = nil, textColor: UIColor, label: String?) -> WLButton {
        let button = WLButton(height: 56, backgroundColor: enabledColor, cornerRadius: 15, label: label, labelFont: .systemFont(ofSize: 17, weight: .semibold), textColor: textColor)
        button.enabledColor = enabledColor
        button.disabledColor = disabledColor
        return button
    }
    var enabledColor: UIColor?
    var disabledColor: UIColor?
    
    override var isEnabled: Bool {
        didSet {
            if let enabledColor = enabledColor, let disabledColor = disabledColor {
                backgroundColor = isEnabled ? enabledColor: disabledColor
            } else {
                isEnabled ? (alpha = 1) : (alpha = 0.5)
            }
        }
    }
}
