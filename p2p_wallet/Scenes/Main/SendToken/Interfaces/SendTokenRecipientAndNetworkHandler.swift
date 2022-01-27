//
//  SendTokenRecipientAndNetworkHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2021.
//

import Foundation
import RxCocoa

protocol SendTokenRecipientAndNetworkHandler {
    var recipientSubject: BehaviorRelay<SendToken.Recipient?> {get}
    var networkSubject: BehaviorRelay<SendToken.Network> {get}
    
    func getSelectedWallet() -> Wallet?
    func getAPIClient() -> SendServiceType
}

extension SendTokenRecipientAndNetworkHandler {
    var recipientDriver: Driver<SendToken.Recipient?> {
        recipientSubject.asDriver()
    }
    
    var networkDriver: Driver<SendToken.Network> {
        networkSubject.asDriver()
    }
    
    func getSelectedRecipient() -> SendToken.Recipient? {
        recipientSubject.value
    }
    
    func getSelectedNetwork() -> SendToken.Network {
        networkSubject.value
    }
    
    func getSelectableNetworks() -> [SendToken.Network] {
        var networks: [SendToken.Network] = [.solana]
        if getSelectedWallet()?.token.isRenBTC == true {
            networks.append(.bitcoin)
        }
        return networks
    }
    
    func selectRecipient(_ recipient: SendToken.Recipient?) {
        recipientSubject.accept(recipient)
        
        if recipient != nil {
            if isRecipientBTCAddress() {
                networkSubject.accept(.bitcoin)
            } else {
                networkSubject.accept(.solana)
            }
        }
    }
    
    func selectNetwork(_ network: SendToken.Network) {
        if getSelectedWallet()?.token.isRenBTC == false {
            networkSubject.accept(.solana)
        }
        networkSubject.accept(network)
    }
    
    // MARK: - Helpers
    private func isRecipientBTCAddress() -> Bool {
        guard let recipient = recipientSubject.value else {return false}
        return recipient.name == nil &&
            recipient.address
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: getAPIClient().isTestNet()))
    }
}
