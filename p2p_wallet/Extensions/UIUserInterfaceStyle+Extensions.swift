//
//  UIUserInterfaceStyle+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/01/2021.
//

import Foundation

extension UIUserInterfaceStyle {
    var localizedString: String {
        var appearance = ""
        switch self {
        case .dark:
            appearance = L10n.dark
        case .light:
            appearance = L10n.light
        default:
            appearance = L10n.system
        }
        return appearance
    }
}
