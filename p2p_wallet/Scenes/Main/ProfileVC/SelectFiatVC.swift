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
    let responder: ChangeFiatResponder
    @Injected private var analyticsManager: AnalyticsManagerType
    init(responder: ChangeFiatResponder) {
        self.responder = responder
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
    }
    
    override func createCell(item: Fiat) -> Cell<Fiat> {
        let cell = super.createCell(item: item)
        cell.label.text = item.name
        return cell
    }
    
    override func itemDidSelect(_ item: Fiat) {
        super.itemDidSelect(item)
        changeFiatToSelectedItem()
    }
    
    private func changeFiatToSelectedItem() {
        analyticsManager.log(event: .settingsСurrencySelected(сurrency: selectedItem.code))
        responder.changeFiat(to: selectedItem)
        UIApplication.shared.showToast(message: "✅ " + L10n.currencyChanged)
    }
}
