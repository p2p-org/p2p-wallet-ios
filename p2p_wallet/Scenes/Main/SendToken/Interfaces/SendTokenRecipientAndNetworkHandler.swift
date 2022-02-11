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
import FeeRelayerSwift

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
            networkSubject,
            payingWalletSubject
        )
            .flatMap {[weak self] _ -> Single<SolanaSDK.FeeAmount?> in
                guard let self = self else {throw SolanaSDK.Error.unknown}
                return self.getFees()
            }
            .asDriver(onErrorJustReturn: nil)
    }
    
    var payingWalletStatusDriver: Driver<SendToken.PayingWalletStatus> {
        Observable.combineLatest(
            feesDriver.asObservable().distinctUntilChanged(),
            payingWalletSubject.distinctUntilChanged()
        )
            .flatMap {[weak self] fees, payingWallet -> Single<SendToken.PayingWalletStatus> in
                guard let self = self, let feeInSOL = fees?.total, let payingWallet = payingWallet else {return .just(.loading)}
                return self.sendService.getFeesInPayingToken(feeInSOL: feeInSOL, payingFeeWallet: payingWallet)
                    .map {amount -> SendToken.PayingWalletStatus in
                        guard let amount = amount else {return .invalid}
                        return .valid(amount: amount, enoughBalance: (payingWallet.lamports ?? 0) >= amount)
                    }
                    .catch { error in
                        if let error = error as? FeeRelayer.Error,
                           error == FeeRelayer.Error.swapPoolsNotFound
                        {
                            return .just(.invalid)
                        }
                        throw error
                    }
                    .catchAndReturn(.invalid)
            }
            .asDriver(onErrorJustReturn: .invalid)
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
        guard let wallet = getSelectedWallet() else {return .just(nil)}
        return sendService.getFees(
            from: wallet,
            receiver: recipientSubject.value?.address,
            network: networkSubject.value,
            payingFeeToken: getPayingToken(payingWallet: payingWalletSubject.value)
        )
            .catchAndReturn(nil)
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
}

private func getPayingToken(payingWallet wallet: Wallet?) -> FeeRelayer.Relay.TokenInfo? {
    guard let wallet = wallet, let address = wallet.pubkey
    else {
        return nil
    }
    return .init(address: address, mint: wallet.mintAddress)
}
