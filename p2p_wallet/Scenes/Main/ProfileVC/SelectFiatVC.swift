//
//  SelectFiatVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/04/2021.
//

import Foundation

protocol ChangeFiatResponder {
    func changeFiat(to fiat: Fiat)
}

class SelectFiatVC: ProfileSingleSelectionVC<Fiat> {
    override var dataDidChange: Bool {selectedItem != Defaults.fiat}
    let responder: ChangeFiatResponder
    let analyticsManager: AnalyticsManagerType
    init(responder: ChangeFiatResponder, analyticsManager: AnalyticsManagerType) {
        self.responder = responder
        self.analyticsManager = analyticsManager
        super.init()
        
        // init data
        Fiat.allCases
            .forEach {
                data[$0] = ($0 == Defaults.fiat)
            }
    }
    
    override func setUp() {
        title = L10n.currency
        super.setUp()
        navigationBar.rightItems.addArrangedSubviews([
            UILabel(text: L10n.done, textSize: 17, weight: .medium, textColor: .h5887ff)
                .onTap(self, action: #selector(saveChange))
        ])
    }
    
    override func createCell(item: Fiat) -> Cell<Fiat> {
        let cell = super.createCell(item: item)
        cell.label.text = item.name
        return cell
    }
    
    @objc func saveChange() {
        showAlert(title: L10n.switchNetwork, message: L10n.doYouReallyWantToSwitchTo + " \"" + selectedItem.name + "\"", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { [weak self] (index) in
            if index != 0 {return}
            self?.changeFiatToSelectedItem()
        }
    }
    
    private func changeFiatToSelectedItem() {
        analyticsManager.log(event: .settingsСurrencySelected(сurrency: selectedItem.code))
        responder.changeFiat(to: selectedItem)
        UIApplication.shared.showToast(message: "✅ " + L10n.currencyChanged)
    }
}
