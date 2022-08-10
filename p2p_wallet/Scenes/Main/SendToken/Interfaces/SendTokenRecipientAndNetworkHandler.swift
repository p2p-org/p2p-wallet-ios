//
//  SendTokenRecipientAndNetworkHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2021.
//

import FeeRelayerSwift
import Foundation
import SolanaSwift
import Combine

protocol SendTokenRecipientAndNetworkHandler: AnyObject {
    var subscriptions: [AnyCancellable] { get set }
    var sendService: SendServiceType { get }
    var recipientSubject: CurrentValueSubject<SendToken.Recipient?, Never> { get }
    var networkSubject: CurrentValueSubject<SendToken.Network, Never> { get }
    var payingWalletSubject: CurrentValueSubject<Wallet?, Never> { get }
    var feeInfoSubject: LoadableRelay<SendToken.FeeInfo> { get }

    func getSelectedWallet() -> Wallet?
    func getSendService() -> SendServiceType
}

extension SendTokenRecipientAndNetworkHandler {
    var recipientDriver: AnyPublisher<SendToken.Recipient?, Never> {
        recipientSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var networkDriver: AnyPublisher<SendToken.Network, Never> {
        networkSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var payingWalletDriver: AnyPublisher<Wallet?, Never> {
        payingWalletSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var feeInfoDriver: AnyPublisher<Loadable<SendToken.FeeInfo>, Never> {
        feeInfoSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
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
        recipientSubject.send(recipient)

        if recipient != nil {
            if isRecipientBTCAddress() {
                networkSubject.send(.bitcoin)
            } else {
                networkSubject.send(.solana)
            }
        }
    }

    func selectNetwork(_ network: SendToken.Network) {
        networkSubject.send(network)

        switch network {
        case .solana:
            if isRecipientBTCAddress() { recipientSubject.send(nil) }
        case .bitcoin:
            if !isRecipientBTCAddress() { recipientSubject.send(nil) }
        }
    }

    func selectPayingWallet(_ payingWallet: Wallet) {
        Defaults.payingTokenMint = payingWallet.mintAddress
        payingWalletSubject.send(payingWallet)
    }

    // MARK: - Helpers

    private func isRecipientBTCAddress() -> Bool {
        guard let recipient = recipientSubject.value else { return false }
        return recipient.name == nil &&
            recipient.address
            .matches(oneOfRegexes: .bitcoinAddress(isTestnet: getSendService().isTestNet()))
    }

    func bindFees() {
        Publishers.CombineLatest3(
            payingWalletSubject.removeDuplicates(),
            recipientSubject.removeDuplicates(),
            networkSubject.removeDuplicates()
        )
            .sink { [weak self] payingWallet, recipient, network in
                guard let self = self else { return }
                
                if let wallet = self.getSelectedWallet() {
                    self.feeInfoSubject.request = Single.async(with: self) { `self` -> SendToken.FeeInfo in
                        let feeAmountInSol = try await self.sendService.getFees(
                            from: wallet,
                            receiver: recipient?.address,
                            network: network,
                            payingTokenMint: payingWallet?.mintAddress
                        )

                        let feeAmountInSOL = feeAmountInSol ?? .zero

                        if feeAmountInSOL.total == 0 {
                            return .init(
                                feeAmount: .zero,
                                feeAmountInSOL: .zero,
                                hasAvailableWalletToPayFee: true
                            )
                        }
                        // else, check available wallets to pay fee
                        guard let payingFeeWallet = payingWallet else {
                            return .init(
                                feeAmount: .zero,
                                feeAmountInSOL: .zero,
                                hasAvailableWalletToPayFee: nil
                            )
                        }

                        let (availableWallets, feeInSPL) = try await(
                            self.sendService.getAvailableWalletsToPayFee(feeInSOL: feeAmountInSOL),
                            self.sendService.getFeesInPayingToken(
                                feeInSOL: feeAmountInSOL,
                                payingFeeWallet: payingFeeWallet
                            )
                        )

                        return .init(
                            feeAmount: feeInSPL ?? .zero, feeAmountInSOL: feeAmountInSOL,
                            hasAvailableWalletToPayFee: availableWallets.isEmpty == false
                        )
                    }
                } else {
                    self.feeInfoSubject
                        .request =
                        .just(.init(feeAmount: .zero, feeAmountInSOL: .zero, hasAvailableWalletToPayFee: nil))
                }
                self.feeInfoSubject.reload()
            }
            .store(in: &subscriptions)
    }
}
