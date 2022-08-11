//
//  SendTokenRecipientAndNetworkHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2021.
//

import Combine
import FeeRelayerSwift
import Foundation
import SolanaSwift

// How to Define a Protocol With @Published Property Wrapper Type
// https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/

protocol SendTokenRecipientAndNetworkHandler: AnyObject {
    var subscriptions: [AnyCancellable] { get set }
    var sendService: SendServiceType { get }
    var wallet: Wallet? { get }

    // MARK: - @Published var recipient

    // Define recipient (wrapped value)
    var recipient: SendToken.Recipient? { get }
    // Define recipient Published property wrapper
    func setRecipient(_ recipient: SendToken.Recipient?)
    // Define recipient publisher
    var recipientPublisher: AnyPublisher<SendToken.Recipient?, Never> { get }

    // MARK: - @Published var network

    // Define network (wrapped value)
    var network: SendToken.Network { get }
    // Define network Published property wrapper
    func setNetwork(_ network: SendToken.Network?)
    // Define network publisher
    var networkPublisher: AnyPublisher<SendToken.Network, Never> { get }

    // MARK: - @Published var payingWallet

    // Define payingWallet (wrapped value)
    var payingWallet: Wallet? { get }
    // Define payingWallet Published property wrapper
    func setPayingWallet(_ payingWallet: Wallet?)
    // Define payingWallet publisher
    var payingWalletPublisher: AnyPublisher<Wallet?, Never> { get }

    var feeInfoSubject: LoadableRelay<SendToken.FeeInfo> { get }

    func getSendService() -> SendServiceType
}

extension SendTokenRecipientAndNetworkHandler {
    var recipientDriver: AnyPublisher<SendToken.Recipient?, Never> {
        recipientPublisher.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var networkDriver: AnyPublisher<SendToken.Network, Never> {
        networkPublisher.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var payingWalletDriver: AnyPublisher<Wallet?, Never> {
        payingWalletPublisher.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var feeInfoDriver: AnyPublisher<Loadable<SendToken.FeeInfo>, Never> {
        feeInfoSubject.eraseToAnyPublisher().receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    func getSelectedRecipient() -> SendToken.Recipient? {
        recipient
    }

    func getSelectedNetwork() -> SendToken.Network {
        network
    }

    func getSelectableNetworks() -> [SendToken.Network] {
        var networks: [SendToken.Network] = [.solana]
        if wallet?.token.isRenBTC == true {
            networks.append(.bitcoin)
        }
        return networks
    }

    func selectRecipient(_ recipient: SendToken.Recipient?) {
        setRecipient(recipient)

        if recipient != nil {
            if isRecipientBTCAddress() {
                setNetwork(.bitcoin)
            } else {
                setNetwork(.solana)
            }
        }
    }

    func selectNetwork(_ network: SendToken.Network) {
        setNetwork(network)

        switch network {
        case .solana:
            if isRecipientBTCAddress() { setRecipient(nil) }
        case .bitcoin:
            if !isRecipientBTCAddress() { setRecipient(nil) }
        }
    }

    func selectPayingWallet(_ payingWallet: Wallet) {
        Defaults.payingTokenMint = payingWallet.mintAddress
        setPayingWallet(payingWallet)
    }

    // MARK: - Helpers

    private func isRecipientBTCAddress() -> Bool {
        guard let recipient = recipient else { return false }
        return recipient.name == nil &&
            recipient.address
            .matches(oneOfRegexes: .bitcoinAddress(isTestnet: getSendService().isTestNet()))
    }

    func bindFees() {
        Publishers.CombineLatest3(
            payingWalletPublisher.removeDuplicates(),
            recipientPublisher.removeDuplicates(),
            networkPublisher.removeDuplicates()
        )
            .sink { [weak self] payingWallet, recipient, network in
                guard let self = self else { return }

                if let wallet = self.wallet {
                    self.feeInfoSubject.request = {
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
                    self.feeInfoSubject.request = {
                        .init(feeAmount: .zero, feeAmountInSOL: .zero, hasAvailableWalletToPayFee: nil)
                    }
                }
                self.feeInfoSubject.reload()
            }
            .store(in: &subscriptions)
    }
}
