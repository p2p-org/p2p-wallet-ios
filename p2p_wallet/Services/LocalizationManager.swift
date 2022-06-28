//
//  LocalizeManager.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 28.10.2021.
//

protocol LocalizationManagerType: AnyObject {
    func selectableLanguages() -> [(LocalizedLanguage, Bool)]
    func changeCurrentLanguage(_: LocalizedLanguage)
}

final class LocalizationManager: LocalizationManagerType {
    private let notSelectableLanguageCodes: Set = ["Base", "ru", "fr"]

    func selectableLanguages() -> [(LocalizedLanguage, Bool)] {
        let currentLanguageCode = currentLanguage().code
        return availableLanguageCodes
            .map { (LocalizedLanguage(code: $0), $0 == currentLanguageCode) }
    }

    func currentLanguage() -> LocalizedLanguage {
        let currentCode = Defaults.localizedLanguage.code

        return notSelectableLanguageCodes.contains(currentCode)
            ? findAppropriateLanguage()
            : LocalizedLanguage(code: currentCode)
    }

    func changeCurrentLanguage(_ language: LocalizedLanguage) {
        Defaults.localizedLanguage = language
    }

    private var availableLanguageCodes: [String] {
        Bundle.main.localizations
            .filter { !notSelectableLanguageCodes.contains($0) }
    }

    private func findAppropriateLanguage() -> LocalizedLanguage {
        let availableCodes = Set(availableLanguageCodes)

        let code = Locale.preferredLanguages
            .map { $0.prefix(2) }
            .map(String.init)
            .first { availableCodes.contains($0) }
            ?? "en"

        return LocalizedLanguage(code: code)
    }
}
