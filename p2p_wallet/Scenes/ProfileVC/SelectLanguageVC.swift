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
        Locale.current.localizedString(forLanguageCode: code)
    }
    static var current: LocalizedLanguage {
        LocalizedLanguage(code: String(Locale.preferredLanguages[0].prefix(2)))
    }
}

class SelectLanguageVC: ProfileSingleSelectionVC<LocalizedLanguage> {
    override var dataDidChange: Bool {selectedItem != LocalizedLanguage.current}
    
    override init() {
        super.init()
        data = [LocalizedLanguage: Bool]()
        Bundle.main.localizations.filter({$0 != "Base"}).forEach {
            print($0)
            data[LocalizedLanguage(code: $0)] = $0 == Locale.preferredLanguages[0].prefix(2)
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
        cell.label.text = item.localizedName
        return cell
    }
    
    override func saveChange() {
        
    }
}
