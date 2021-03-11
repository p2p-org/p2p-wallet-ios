//
//  SelectNetworkVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation

protocol ChangeNetworkResponder {
    func changeNetwork(to network: SolanaSDK.Network)
}

class SelectNetworkVC: ProfileSingleSelectionVC<SolanaSDK.Network> {
    override var dataDidChange: Bool {selectedItem != Defaults.network}
    var accountStorage: SolanaSDKAccountStorage
    let rootViewModel: RootViewModel
    let changeNetworkResponder: ChangeNetworkResponder
    
    init(accountStorage: SolanaSDKAccountStorage, rootViewModel: RootViewModel, changeNetworkResponder: ChangeNetworkResponder) {
        self.accountStorage = accountStorage
        self.rootViewModel = rootViewModel
        self.changeNetworkResponder = changeNetworkResponder
        super.init()
        // initial data
        SolanaSDK.Network.allCases.forEach {
            data[$0] = ($0 == Defaults.network)
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
    
    override func createCell(item: SolanaSDK.Network) -> Cell<SolanaSDK.Network> {
        let cell = super.createCell(item: item)
        cell.label.text = item.cluster
        return cell
    }
    
    @objc func saveChange() {
        showAlert(title: L10n.switchNetwork, message: L10n.doYouReallyWantToSwitchTo + " \"" + selectedItem.cluster + "\"", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { (index) in
            if index != 0 {return}
            UIApplication.shared.showIndetermineHudWithMessage(L10n.switchingTo + " \"" + self.selectedItem.cluster + "\"")
            DispatchQueue.global().async {
                do {
                    let account = try SolanaSDK.Account(phrase: self.accountStorage.account!.phrase, network: self.selectedItem)
                    try self.accountStorage.save(account)
                    DispatchQueue.main.async {
                        UIApplication.shared.hideHud()
                        self.changeNetworkResponder.changeNetwork(to: self.selectedItem)
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
