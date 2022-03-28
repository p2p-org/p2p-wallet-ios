//
//  Locale+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/01/2021.
//

import Foundation

extension Locale {
    static var shared: Locale {
        Locale(identifier: Defaults.localizedLanguage.code)
    }
}
