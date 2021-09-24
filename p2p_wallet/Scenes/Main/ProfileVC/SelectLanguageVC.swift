//
//  SelectLanguageVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/01/2021.
//

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

protocol ChangeLanguageResponder {
    func languageDidChange(to: LocalizedLanguage)
}

class SelectLanguageVC: ProfileSingleSelectionVC<LocalizedLanguage> {
    @Injected private var responder: ChangeLanguageResponder
    
    override init() {
        super.init()
        data = [LocalizedLanguage: Bool]()
        Bundle.main.localizations.filter({$0 != "Base"}).forEach {
            data[LocalizedLanguage(code: $0)] = $0 == Defaults.localizedLanguage.code
        }
    }
    
    override func setUp() {
        title = L10n.language
        super.setUp()
    }
    
    override func createCell(item: LocalizedLanguage) -> Cell<LocalizedLanguage> {
        let cell = super.createCell(item: item)
        cell.label.text = item.originalName?.uppercaseFirst
        return cell
    }
    
    override func itemDidSelect(_ item: LocalizedLanguage) {
        let originalSelectedItem = selectedItem
        super.itemDidSelect(item)
        showAlert(title: L10n.switchLanguage, message: L10n.doYouReallyWantToSwitchTo + " " + selectedItem.localizedName?.uppercaseFirst + "?", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { [weak self] (index) in
            guard index == 0, let language = self?.selectedItem
            else {
                self?.reverseSelectedItem(originalSelectedItem: originalSelectedItem)
                return
            }
            self?.responder.languageDidChange(to: language)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let language = language.originalName {
                    UIApplication.shared.showToast(message: "✅ " + L10n.changedLanguageTo(language))
                } else {
                    UIApplication.shared.showToast(message: "✅ " + L10n.interfaceLanguageChanged)
                }
                
            }
        }
    }
    
    private func reverseSelectedItem(originalSelectedItem: LocalizedLanguage)
    {
        super.itemDidSelect(originalSelectedItem)
    }
}
