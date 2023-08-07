import Foundation

extension Locale {
    static var shared: Locale {
        Locale(identifier: Defaults.localizedLanguage.code)
    }

    static var base: Locale {
        Locale(identifier: "en-US")
    }
}
