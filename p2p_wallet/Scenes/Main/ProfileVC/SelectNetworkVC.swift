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
    let responder: ChangeNetworkResponder
    let analyticsManger: AnalyticsManagerType
    let renVMService: RenVMServiceType
    
    init(
        changeNetworkResponder: ChangeNetworkResponder,
        analyticsManger: AnalyticsManagerType,
        renVMService: RenVMServiceType
    ) {
        self.responder = changeNetworkResponder
        self.analyticsManger = analyticsManger
        self.renVMService = renVMService
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
    }
    
    override func createCell(item: SolanaSDK.APIEndPoint) -> Cell<SolanaSDK.APIEndPoint> {
        let cell = super.createCell(item: item)
        cell.label.text = item.url
        return cell
    }
    
    override func itemDidSelect(_ item: SolanaSDK.APIEndPoint) {
        let originalSelectedItem = selectedItem
        super.itemDidSelect(item)
        showAlert(title: L10n.switchNetwork, message: L10n.doYouReallyWantToSwitchTo + " \"" + selectedItem.url + "\"", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { [weak self] (index) in
            guard index == 0 else {
                self?.reverseChange(originalSelectedItem: originalSelectedItem)
                return
            }
            if let url = self?.selectedItem.url {
                self?.analyticsManger.log(event: .settingsNetworkSelected(network: url))
            }
            
            self?.changeNetworkToSelectedNetwork()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIApplication.shared.showToast(message: "✅ " + L10n.networkChanged)
            }
        }
    }
    
    private func changeNetworkToSelectedNetwork() {
        if Defaults.apiEndPoint.network != selectedItem.network {
            renVMService.expireCurrentSession()
        }
        
        responder.changeAPIEndpoint(to: selectedItem)
    }
    
    private func reverseChange(originalSelectedItem: SolanaSDK.APIEndPoint)
    {
        super.itemDidSelect(originalSelectedItem)
    }
}
