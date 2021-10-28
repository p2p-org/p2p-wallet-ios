//
//  LocalizeManager.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 28.10.2021.
//

protocol LocalizationManagerType: AnyObject {
    func selectableLanguages() -> [LocalizedLanguage: Bool]
}

final class LocalizationManager: LocalizationManagerType {
    func selectableLanguages() -> [LocalizedLanguage: Bool] {
        let languages = Bundle.main.localizations
            .filter { $0 != "Base" }
            .filter { $0 != "ru" }
            .filter { $0 != "fr" }
            .map { (LocalizedLanguage(code: $0), $0 == Defaults.localizedLanguage.code) }

        return Dictionary(uniqueKeysWithValues: languages)
    }
}
