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

class SelectLanguageVC: ProfileSingleSelectionVC<LocalizedLanguage> {
    override var dataDidChange: Bool {selectedItem != Defaults.localizedLanguage}
    
    override init() {
        super.init()
        data = [LocalizedLanguage: Bool]()
        Bundle.main.localizations.filter({$0 != "Base"}).forEach {
            print($0)
            data[LocalizedLanguage(code: $0)] = $0 == Defaults.localizedLanguage.code
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        title = L10n.language
        super.setUp()
    }
    
    override func createCell(item: LocalizedLanguage) -> Cell<LocalizedLanguage> {
        let cell = super.createCell(item: item)
        cell.label.text = item.localizedName?.uppercaseFirst
        return cell
    }
    
    override func saveChange() {
        showAlert(title: L10n.switchLanguage, message: L10n.doYouReallyWantToSwitchTo + " " + selectedItem.localizedName?.uppercaseFirst + "?", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { (index) in
            if index != 0 {return}
            Defaults.localizedLanguage = self.selectedItem
            AppDelegate.shared.reloadRootVC()
        }
    }
}
