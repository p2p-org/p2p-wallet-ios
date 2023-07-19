import Foundation
import Resolver
import UIKit

extension Bundle {
    fileprivate static var current: Bundle = valueForCurrentBundle()

    // MARK: - Localization swizzle

    @objc func myLocalizedString(forKey key: String, value: String?, table: String?) -> String {
        Bundle.current.myLocalizedString(forKey: key, value: value, table: table)
    }

    fileprivate static func valueForCurrentBundle() -> Bundle {
        let currentLanguage = Resolver.resolve(LocalizationManagerType.self).currentLanguage()

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
