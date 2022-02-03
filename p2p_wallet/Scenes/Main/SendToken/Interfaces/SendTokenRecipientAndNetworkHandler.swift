//
//  SendTokenRecipientAndNetworkHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2021.
//

import Foundation
import RxSwift
import RxCocoa
import SolanaSwift

protocol SendTokenRecipientAndNetworkHandler: AnyObject {
    var sendService: SendServiceType {get}
    var recipientSubject: BehaviorRelay<SendToken.Recipient?> {get}
    var networkSubject: BehaviorRelay<SendToken.Network> {get}
    var payingWalletSubject: BehaviorRelay<Wallet?> {get}
    
    func getSelectedWallet() -> Wallet?
    func getSendService() -> SendServiceType
}

extension SendTokenRecipientAndNetworkHandler {
    var recipientDriver: Driver<SendToken.Recipient?> {
        recipientSubject.asDriver()
    }
    
    var networkDriver: Driver<SendToken.Network> {
        networkSubject.asDriver()
    }
    
    var feesDriver: Driver<SolanaSDK.FeeAmount?> {
        Observable.combineLatest(
            recipientSubject,
            networkSubject
        )
            .flatMap {[weak self] recipient, network -> Single<SolanaSDK.FeeAmount?> in
                guard let self = self else {throw SolanaSDK.Error.unknown}
                return self.getFees(recipient: recipient, network: network)
            }
            .asDriver(onErrorJustReturn: nil)
    }
    
    var payingWalletDriver: Driver<Wallet?> {
        payingWalletSubject.asDriver()
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
    
    func getFees() -> Single<SolanaSDK.FeeAmount?> {
        getFees(recipient: recipientSubject.value, network: networkSubject.value)
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
    
    func selectPayingWallet(_ payingWallet: Wallet) {
        payingWalletSubject.accept(payingWallet)
    }
    
    // MARK: - Helpers
    private func isRecipientBTCAddress() -> Bool {
        guard let recipient = recipientSubject.value else {return false}
        return recipient.name == nil &&
            recipient.address
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: getSendService().isTestNet()))
    }
    
    private func getFees(recipient: SendToken.Recipient?, network: SendToken.Network) -> Single<SolanaSDK.FeeAmount?> {
        guard let wallet = getSelectedWallet() else {return .just(nil)}
        return sendService.getFees(
            from: wallet,
            receiver: recipient?.address,
            network: network
        )
            .catchAndReturn(nil)
    }
}
