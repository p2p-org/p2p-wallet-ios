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
    var disposeBag: DisposeBag {get}
    var sendService: SendServiceType {get}
    var recipientSubject: BehaviorRelay<SendToken.Recipient?> {get}
    var networkSubject: BehaviorRelay<SendToken.Network> {get}
    var feeInfoSubject: LoadableRelay<SendToken.FeeInfo> {get}
    
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
    
    var feeInfoDriver: Driver<Loadable<SendToken.FeeInfo>> {
        feeInfoSubject.asDriver()
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
        reloadFeeInfoSubject()
    }
    
    func selectNetwork(_ network: SendToken.Network) {
        networkSubject.accept(network)
        
        switch network {
        case .solana:
            if isRecipientBTCAddress() {recipientSubject.accept(nil)}
        case .bitcoin:
            if !isRecipientBTCAddress() {recipientSubject.accept(nil)}
        }
        
        reloadFeeInfoSubject()
    }
    
    func selectPayingWallet(_ payingWallet: Wallet) {
        Defaults.payingTokenMint = payingWallet.mintAddress
        reloadFeeInfoSubject(payingWallet: payingWallet)
    }
    
    // MARK: - Helpers
    private func isRecipientBTCAddress() -> Bool {
        guard let recipient = recipientSubject.value else {return false}
        return recipient.name == nil &&
            recipient.address
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: getSendService().isTestNet()))
    }
    
    private func reloadFeeInfoSubject(
        wallet: Wallet? = nil,
        recipient: String? = nil,
        network: SendToken.Network? = nil,
        payingWallet: Wallet? = nil
    ) {
        let payingWallet = payingWallet ?? feeInfoSubject.value?.wallet
        if let wallet = getSelectedWallet() {
            feeInfoSubject.request = sendService
                .getFees(
                    from: wallet,
                    receiver: recipient ?? recipientSubject.value?.address,
                    network: network ?? networkSubject.value,
                    isPayingWithSOL: payingWallet?.isNativeSOL == true
                )
                .flatMap { [weak self] feeAmountInSOL -> Single<(SolanaSDK.FeeAmount, SolanaSDK.FeeAmount)> in
                    guard let sendService = self?.sendService else {
                        throw SolanaSDK.Error.unknown
                    }
                    guard let feeAmountInSOL = feeAmountInSOL else {
                        return .just((.zero, .zero))
                    }
                    guard let payingWallet = payingWallet else {
                        return .just((feeAmountInSOL, .zero))
                    }

                    return sendService.getFeesInPayingToken(
                        feeInSOL: feeAmountInSOL,
                        payingFeeWallet: payingWallet
                    )
                        .map { (feeAmountInSOL, ($0 ?? .zero)) }
                }
                .map { .init(wallet: payingWallet, feeAmount: $0.1, feeAmountInSOL: $0.0)}
        } else {
            feeInfoSubject.request = .just(.init(wallet: payingWallet, feeAmount: .zero, feeAmountInSOL: .zero))
        }
        feeInfoSubject.reload()
    }
}

private func getPayingToken(payingWallet wallet: Wallet?) -> FeeRelayer.Relay.TokenInfo? {
    guard let wallet = wallet, let address = wallet.pubkey
    else {
        return nil
    }
    return .init(address: address, mint: wallet.mintAddress)
}
