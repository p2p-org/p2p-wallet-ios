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
}

protocol ChangeLanguageResponder {
    func languageDidChange(to: LocalizedLanguage)
}

class SelectLanguageVC: ProfileSingleSelectionVC<LocalizedLanguage> {
    override var dataDidChange: Bool {selectedItem != Defaults.localizedLanguage}
    
    let responder: ChangeLanguageResponder
    init(responder: ChangeLanguageResponder) {
        self.responder = responder
        super.init()
        data = [LocalizedLanguage: Bool]()
        Bundle.main.localizations.filter({$0 != "Base"}).forEach {
            print($0)
            data[LocalizedLanguage(code: $0)] = $0 == Defaults.localizedLanguage.code
        }
    }
    
    override func setUp() {
        title = L10n.language
        super.setUp()
        navigationBar.rightItems.addArrangedSubviews([
            UILabel(text: L10n.done, textSize: 17, weight: .medium, textColor: .h5887ff)
                .onTap(self, action: #selector(saveChange))
        ])
    }
    
    override func createCell(item: LocalizedLanguage) -> Cell<LocalizedLanguage> {
        let cell = super.createCell(item: item)
        cell.label.text = item.localizedName?.uppercaseFirst
        return cell
    }
    
    @objc func saveChange() {
        showAlert(title: L10n.switchLanguage, message: L10n.doYouReallyWantToSwitchTo + " " + selectedItem.localizedName?.uppercaseFirst + "?", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { [weak self] (index) in
            guard index == 0, let language = self?.selectedItem else {return}
            self?.responder.languageDidChange(to: language)
        }
    }
}
