//
//  LocalizeManager.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 28.10.2021.
//

import OrderedCollections

protocol LocalizationManagerType: AnyObject {
    func selectableLanguages() -> OrderedDictionary<LocalizedLanguage, Bool>
    func changeCurrentLanguage(_: LocalizedLanguage)
}

final class LocalizationManager: LocalizationManagerType {
    private let notSelectableLanguageCodes: Set = ["Base", "ru", "fr"]

    func selectableLanguages() -> OrderedDictionary<LocalizedLanguage, Bool> {
        let currentLanguageCode = currentLanguage().code

        let languages = availableLanguageCodes
            .map { (LocalizedLanguage(code: $0), $0 == currentLanguageCode) }

        return OrderedDictionary(uniqueKeysWithValues: languages)
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
