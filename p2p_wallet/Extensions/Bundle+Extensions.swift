//
//  Bundle+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/01/2021.
//

import Foundation

extension Bundle {
    fileprivate static var current: Bundle = valueForCurrentBundle()

    static func swizzleLocalization() {
        swizzle(
            originalSelector: #selector(localizedString(forKey:value:table:)),
            newSelector:
            #selector(myLocalizedString(forKey:value:table:))
        )
    }

    @objc func myLocalizedString(forKey key: String, value: String?, table: String?) -> String {
        Bundle.current.myLocalizedString(forKey: key, value: value, table: table)
    }

    fileprivate static func valueForCurrentBundle() -> Bundle {
        let currentLanguage = LocalizationManager().currentLanguage()

        return main.path(forResource: currentLanguage.code, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? main
    }
}

extension UIApplication {
    static func languageChanged() {
        Bundle.current = Bundle.valueForCurrentBundle()
    }
}
