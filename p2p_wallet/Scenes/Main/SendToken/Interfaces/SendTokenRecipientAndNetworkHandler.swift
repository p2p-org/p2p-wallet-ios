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
    
    var feesDriver: Driver<SolanaSDK.FeeAmount> {
        Observable.combineLatest(
            recipientSubject,
            networkSubject
        )
            .flatMap {[weak self] recipient, network -> Single<SolanaSDK.FeeAmount> in
                guard let self = self else {throw SolanaSDK.Error.unknown}
                guard let wallet = self.getSelectedWallet() else {return .just(.init(transaction: 0, accountBalances: 0))}
                return self.sendService.getFees(
                    from: wallet,
                    receiver: recipient?.address,
                    network: network
                )
            }
            .asDriver(onErrorJustReturn: .init(transaction: 0, accountBalances: 0))
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
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: getSendService().isTestNet()))
    }
}
