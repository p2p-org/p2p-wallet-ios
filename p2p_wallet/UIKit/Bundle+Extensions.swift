//
//  Bundle+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/01/2021.
//

import Foundation

extension Bundle {
    fileprivate static var current: Bundle = {
        if let bundlePath = Bundle.main.path(forResource: Defaults.localizedLanguage.code, ofType: "lproj")
        {
            return Bundle(path: bundlePath) ?? main
        }
        
        return main
    }()
    
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
}

extension UIApplication {
    static func changeLanguage(to language: LocalizedLanguage) {
        Defaults.localizedLanguage = language
        
        // change current bundle
        if let bundlePath = Bundle.main.path(forResource: Defaults.localizedLanguage.code, ofType: "lproj")
        {
            Bundle.current = Bundle(path: bundlePath) ?? Bundle.main
        } else {
            Bundle.current = Bundle.main
        }
    }
}
