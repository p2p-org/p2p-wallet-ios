//
//  SelectNetworkVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation

class SelectNetworkVC: ProfileVCBase {
    
    lazy var data: [SolanaSDK.Network: Bool] = {
        var data = [SolanaSDK.Network: Bool]()
        SolanaSDK.Network.allCases.forEach {
            data[$0] = ($0 == Defaults.network)
        }
        return data
    }()
    var cells: [Cell] {stackView.arrangedSubviews.filter {$0 is Cell} as! [Cell]}
    override var dataDidChange: Bool {selectedNetwork != Defaults.network}
    var selectedNetwork: SolanaSDK.Network {data.first(where: {$0.value})!.key}
    
    override func setUp() {
        title = L10n.network
        super.setUp()
        stackView.addArrangedSubviews(data.keys.sorted(by: {(data[$0] ?? data[$1] ?? false)}).map {self.createCell(network: $0)})
        reloadData()
    }
    
    func reloadData() {
        for cell in cells {
            guard let network = cell.network else {continue}
            cell.checkBox.isSelected = data[network] ?? false
        }
    }
    
    @objc func rowDidSelect(_ gesture: UIGestureRecognizer) {
        guard let cell = gesture.view as? Cell,
              let network = cell.network,
              let isCellSelected = data[network],
              isCellSelected == false
        else {return}
        
        data[network] = true
        
        // deselect all other networks
        data.keys.filter {$0 != network}.forEach {data[$0] = false}
        
        reloadData()
    }
    
    override func saveChange() {
        showAlert(title: L10n.switchNetwork, message: L10n.doYouReallyWantToSwitchTo + " \"" + selectedNetwork.cluster + "\"", buttonTitles: [L10n.ok, L10n.cancel], highlightedButtonIndex: 0) { (index) in
            if index != 0 {return}
            UIApplication.shared.showIndetermineHudWithMessage(L10n.switchingTo + " \"" + self.selectedNetwork.cluster + "\"")
            DispatchQueue.global().async {
                do {
                    let account = try SolanaSDK.Account(phrase: AccountStorage.shared.account!.phrase, network: self.selectedNetwork.cluster)
                    try AccountStorage.shared.save(account)
                    DispatchQueue.main.async {
                        UIApplication.shared.hideHud()
                        // save
                        Defaults.network = self.selectedNetwork
                        
                        // refresh sdk
                        SolanaSDK.shared = SolanaSDK(endpoint: Defaults.network.endpoint, accountStorage: AccountStorage.shared)
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
    
    private func createCell(network: SolanaSDK.Network) -> Cell {
        let cell = Cell(height: 66)
        cell.setUp(network: network)
        cell.onTap(self, action: #selector(rowDidSelect(_:)))
        return cell
    }
}

extension SelectNetworkVC {
    class Cell: BEView {
        var network: SolanaSDK.Network?
        
        lazy var label = UILabel(textSize: 15)
        
        lazy var checkBox: BECheckbox = {
            let checkBox = BECheckbox(width: 20, height: 20, cornerRadius: 10)
            checkBox.isUserInteractionEnabled = false
            return checkBox
        }()
        
        override func commonInit() {
            super.commonInit()
            self.row([label, checkBox])
        }
        
        func setUp(network: SolanaSDK.Network) {
            self.network = network
            label.text = network.cluster
        }
    }
}
