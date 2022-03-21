//
//  WLView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import UIKit

class WLButton: UIButton {
    enum StepButtonType: Equatable {
        case black, sub, blue, gray, white
        var backgroundColor: UIColor {
            switch self {
            case .black:
                return .blackButtonBackground
            case .sub:
                return .h2b2b2b
            case .blue:
                return .h5887ff
            case .gray:
                return .grayPanel
            case .white:
                return .white
            }
        }

        var disabledColor: UIColor? {
            switch self {
            case .blue:
                return .a3a5ba.onDarkMode(.h404040)
            default:
                return nil
            }
        }

        var textColor: UIColor {
            switch self {
            case .gray:
                return .textBlack
            case .sub, .blue, .black:
                return .white
            case .white:
                return .h5887ff
            }
        }
    }

    static func stepButton(
        type: StepButtonType,
        label: String?,
        labelFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .semibold),
        labelColor: UIColor? = nil
    ) -> WLButton {
        let button = WLButton(
            backgroundColor: type.backgroundColor,
            cornerRadius: 15,
            label: label,
            labelFont: labelFont,
            textColor: labelColor != nil ? labelColor! : type.textColor
        )
        button.enabledColor = type.backgroundColor
        button.disabledColor = type.disabledColor
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.contentEdgeInsets = .init(x: 15, y: 20)
        return button
    }

    static func stepButton(enabledColor: UIColor, disabledColor: UIColor? = nil, textColor: UIColor,
                           label: String?) -> WLButton
    {
        let button = WLButton(
            backgroundColor: enabledColor,
            cornerRadius: 15,
            label: label,
            labelFont: .systemFont(ofSize: 17, weight: .semibold),
            textColor: textColor
        )
        button.enabledColor = enabledColor
        button.disabledColor = disabledColor

        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.contentEdgeInsets = .init(x: 15, y: 20)
        return button
    }

    var enabledColor: UIColor?
    var disabledColor: UIColor?

    override var isEnabled: Bool {
        didSet {
            if let enabledColor = enabledColor, let disabledColor = disabledColor {
                backgroundColor = isEnabled ? enabledColor : disabledColor
            } else {
                isEnabled ? (alpha = 1) : (alpha = 0.5)
            }
        }
    }
}
