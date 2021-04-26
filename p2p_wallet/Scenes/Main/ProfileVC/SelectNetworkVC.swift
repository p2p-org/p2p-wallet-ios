//
//  SelectNetworkVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation

protocol ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint)
}

class SelectNetworkVC: ProfileSingleSelectionVC<SolanaSDK.APIEndPoint> {
    override var dataDidChange: Bool {selectedItem != Defaults.apiEndPoint}
    var accountStorage: SolanaSDKAccountStorage
    let rootViewModel: RootViewModel
    let changeNetworkResponder: ChangeNetworkResponder
    
    init(accountStorage: SolanaSDKAccountStorage, rootViewModel: RootViewModel, changeNetworkResponder: ChangeNetworkResponder) {
        self.accountStorage = accountStorage
        self.rootViewModel = rootViewModel
        self.changeNetworkResponder = changeNetworkResponder
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
        showAlert(title: L10n.switchNetwork, message: L10n.doYouReallyWantToSwitchTo + " \"" + selectedItem.url + "\"", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { (index) in
            if index != 0 {return}
            UIApplication.shared.showIndetermineHudWithMessage(L10n.switchingNetwork)
            DispatchQueue.global().async {
                do {
                    let account = try SolanaSDK.Account(phrase: self.accountStorage.account!.phrase, network: self.selectedItem.network)
                    try self.accountStorage.save(account)
                    DispatchQueue.main.async {
                        UIApplication.shared.hideHud()
                        self.changeNetworkResponder.changeAPIEndpoint(to: self.selectedItem)
                        self.rootViewModel.reload()
                    }
                } catch {
                    DispatchQueue.main.async {
                        UIApplication.shared.hideHud()
                        self.showError(error, additionalMessage: L10n.pleaseTryAgainLater)
                    }
                }
            }
        }
    }
}
