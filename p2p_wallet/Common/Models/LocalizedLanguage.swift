import Foundation

struct LocalizedLanguage: Hashable, Codable, DefaultsSerializable {
    var code: String

    var localizedName: String? {
        Locale.shared.localizedString(forLanguageCode: code)
    }

    var originalName: String? {
        Locale(identifier: code).localizedString(forLanguageCode: code)
    }
}
