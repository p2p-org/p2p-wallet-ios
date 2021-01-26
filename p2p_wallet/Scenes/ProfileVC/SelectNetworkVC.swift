//
//  SelectNetworkVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation

class SelectNetworkVC: ProfileSingleSelectionVC<SolanaSDK.Network> {
    override var dataDidChange: Bool {selectedItem != Defaults.network}
    
    override init() {
        super.init()
        // initial data
        SolanaSDK.Network.allCases.forEach {
            data[$0] = ($0 == Defaults.network)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        title = L10n.network
        super.setUp()
    }
    
    override func createCell(item: SolanaSDK.Network) -> Cell<SolanaSDK.Network> {
        let cell = super.createCell(item: item)
        cell.label.text = item.cluster
        return cell
    }
    
    override func saveChange() {
        showAlert(title: L10n.switchNetwork, message: L10n.doYouReallyWantToSwitchTo + " \"" + selectedItem.cluster + "\"", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { (index) in
            if index != 0 {return}
            UIApplication.shared.showIndetermineHudWithMessage(L10n.switchingTo + " \"" + self.selectedItem.cluster + "\"")
            DispatchQueue.global().async {
                do {
                    let account = try SolanaSDK.Account(phrase: AccountStorage.shared.account!.phrase, network: self.selectedItem)
                    try AccountStorage.shared.save(account)
                    DispatchQueue.main.async {
                        UIApplication.shared.hideHud()
                        // save
                        Defaults.network = self.selectedItem
                        
                        // refresh sdk
                        SolanaSDK.shared = SolanaSDK(network: Defaults.network, accountStorage: AccountStorage.shared)
                        SolanaSDK.Socket.shared.disconnect()
                        SolanaSDK.Socket.shared = SolanaSDK.Socket(endpoint: Defaults.network.endpoint.replacingOccurrences(of: "http", with: "ws"), publicKey: SolanaSDK.shared.accountStorage.account?.publicKey)
                        
                        AppDelegate.shared.reloadRootVC()
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
