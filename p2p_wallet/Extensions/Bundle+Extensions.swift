//
//  Bundle+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/01/2021.
//

import Foundation

extension Bundle {
    static func swizzleLocalization() {
        swizzle(
            originalSelector: #selector(localizedString(forKey:value:table:)),
            newSelector:
                #selector(myLocalizedString(forKey:value:table:))
        )
    }

    @objc func myLocalizedString(forKey key: String, value: String?, table: String?) -> String {
        guard let bundlePath = Bundle.main.path(forResource: Defaults.localizedLanguage.code, ofType: "lproj"),
            let bundle = Bundle(path: bundlePath) else {
                return Bundle.main.myLocalizedString(forKey: key, value: value, table: table)
        }
        return bundle.myLocalizedString(forKey: key, value: value, table: table)
    }
}
