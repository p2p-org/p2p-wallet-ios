//
//  SendTokenRecipientAndNetworkHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2021.
//

import FeeRelayerSwift
import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

protocol SendTokenRecipientAndNetworkHandler: AnyObject {
    var disposeBag: DisposeBag { get }
    var sendService: SendServiceType { get }
    var recipientSubject: BehaviorRelay<SendToken.Recipient?> { get }
    var networkSubject: BehaviorRelay<SendToken.Network> { get }
    var payingWalletSubject: BehaviorRelay<Wallet?> { get }
    var feeInfoSubject: LoadableRelay<SendToken.FeeInfo> { get }

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

    var payingWalletDriver: Driver<Wallet?> {
        payingWalletSubject.asDriver()
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
    }

    func selectNetwork(_ network: SendToken.Network) {
        networkSubject.accept(network)

        switch network {
        case .solana:
            if isRecipientBTCAddress() { recipientSubject.accept(nil) }
        case .bitcoin:
            if !isRecipientBTCAddress() { recipientSubject.accept(nil) }
        }
    }

    func selectPayingWallet(_ payingWallet: Wallet) {
        Defaults.payingTokenMint = payingWallet.mintAddress
        payingWalletSubject.accept(payingWallet)
    }

    // MARK: - Helpers

    private func isRecipientBTCAddress() -> Bool {
        guard let recipient = recipientSubject.value else { return false }
        return recipient.name == nil &&
            recipient.address
            .matches(oneOfRegexes: .bitcoinAddress(isTestnet: getSendService().isTestNet()))
    }

    func bindFees(walletSubject: BehaviorRelay<Wallet?>? = nil) {
        var observables = [
            payingWalletSubject.distinctUntilChanged().map { $0 as Any },
            recipientSubject.distinctUntilChanged().map { $0 as Any },
            networkSubject.distinctUntilChanged().map { $0 as Any },
        ]

        if let walletSubject = walletSubject {
            observables.append(walletSubject.distinctUntilChanged().map { $0 as Any })
        }

        Observable.combineLatest(observables)
            .subscribe(onNext: { [weak self] params in
                let payingWallet = params[0] as? Wallet
                let recipient = params[1] as? SendToken.Recipient
                let network = params[2] as! SendToken.Network

                guard let self = self else { return }
                if let wallet = self.getSelectedWallet() {
                    self.feeInfoSubject.request = self.sendService
                        .getFees(
                            from: wallet,
                            receiver: recipient?.address,
                            network: network,
                            payingTokenMint: payingWallet?.mintAddress
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
                            .map { (feeAmountInSOL, $0 ?? .zero) }
                        }
                        .map { .init(feeAmount: $0.1, feeAmountInSOL: $0.0) }
                } else {
                    self.feeInfoSubject.request = .just(.init(feeAmount: .zero, feeAmountInSOL: .zero))
                }
                self.feeInfoSubject.reload()
            })
            .disposed(by: disposeBag)
    }
}
