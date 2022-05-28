//
//  Bundle+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/01/2021.
//

import Foundation

extension Bundle {
    fileprivate static var current: Bundle = valueForCurrentBundle()

    // MARK: - Localization swizzle

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

    // MARK: - Build number, marketing number

    var releaseVersionNumber: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersionNumber: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }

    var fullVersionNumber: String? {
        guard let releaseVersionNumber = releaseVersionNumber,
              let buildVersionNumber = buildVersionNumber
        else {
            return nil
        }
        return releaseVersionNumber + "(" + buildVersionNumber + ")"
    }
}

extension UIApplication {
    static func languageChanged() {
        Bundle.current = Bundle.valueForCurrentBundle()
    }
}
