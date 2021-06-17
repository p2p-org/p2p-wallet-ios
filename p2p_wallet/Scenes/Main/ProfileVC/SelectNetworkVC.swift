//
//  SelectNetworkVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation
import RxSwift

protocol ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint)
}

class SelectNetworkVC: ProfileSingleSelectionVC<SolanaSDK.APIEndPoint> {
    override var dataDidChange: Bool {selectedItem != Defaults.apiEndPoint}
    let responder: ChangeNetworkResponder
    let analyticsManger: AnalyticsManagerType
    
    init(changeNetworkResponder: ChangeNetworkResponder, analyticsManger: AnalyticsManagerType) {
        self.responder = changeNetworkResponder
        self.analyticsManger = analyticsManger
        super.init()
        // initial data
        SolanaSDK.APIEndPoint.definedEndpoints
            .forEach {
                data[$0] = ($0 == Defaults.apiEndPoint)
            }
    }
    
    override func setUp() {
        title = L10n.network
        super.setUp()
        navigationBar.rightItems.addArrangedSubviews([
            UILabel(text: L10n.done, textSize: 17, weight: .medium, textColor: .h5887ff)
                .onTap(self, action: #selector(saveChange))
        ])
    }
    
    override func createCell(item: SolanaSDK.APIEndPoint) -> Cell<SolanaSDK.APIEndPoint> {
        let cell = super.createCell(item: item)
        cell.label.text = item.url
        return cell
    }
    
    @objc func saveChange() {
        showAlert(title: L10n.switchNetwork, message: L10n.doYouReallyWantToSwitchTo + " \"" + selectedItem.url + "\"", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { [weak self] (index) in
            if index != 0 {return}
            if let url = self?.selectedItem.url {
                self?.analyticsManger.log(event: .settingsNetworkClick, params: ["endpoint": url])
            }
            
            self?.changeNetworkToSelectedNetwork()
        }
    }
    
    func changeNetworkToSelectedNetwork() {
        responder.changeAPIEndpoint(to: selectedItem)
    }
}
