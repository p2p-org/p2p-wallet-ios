//
//  WalletDetail.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift
import TransactionParser

protocol WalletDetailViewModelType {
    var walletsRepository: WalletsRepository { get }
    var navigatableScenePublisher: AnyPublisher<WalletDetail.NavigatableScene?, Never> { get }
    var walletPublisher: AnyPublisher<Wallet?, Never> { get }
    var walletActionsPublisher: AnyPublisher<[WalletActionType], Never> { get }

    func showWalletSettings()
    func start(action: WalletActionType)
    func showTransaction(_ transaction: ParsedTransaction)
    var pubkey: String { get }
    var symbol: String { get }
}

extension WalletDetail {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        @Injected var walletsRepository: WalletsRepository
        let pubkey: String
        let symbol: String
        @Injected var analyticsManager: AnalyticsManager

        // MARK: - Properties

        private var subscriptions = [AnyCancellable]()

        // MARK: - Subject

        @Published private var navigatableSceneSubject: NavigatableScene?
        @Published private var walletSubject: Wallet?

        // MARK: - Initializer

        init(pubkey: String, symbol: String) {
            self.pubkey = pubkey
            self.symbol = symbol
            bind()
        }

        deinit {
            print("\(String(describing: self)) deinited")
        }

        /// Bind subjects
        private func bind() {
            bindSubjectsIntoSubjects()
        }

        private func bindSubjectsIntoSubjects() {
            walletsRepository
                .dataPublisher
                .map { [weak self] in $0.first(where: { $0.pubkey == self?.pubkey }) }
                .filter { $0 != nil }
                .assign(to: \.walletSubject, on: self)
                .store(in: &subscriptions)

            $walletSubject
                .filter { $0 != nil }
                .map { $0!.token.symbol }
                .prefix(1)
                .sink { [weak self] ticker in
                    self?.analyticsManager.log(event: .tokenDetailsOpen(tokenTicker: ticker))
                }
                .store(in: &subscriptions)
        }

        private func sendTokens() {
            guard let wallet = walletSubject else { return }
            analyticsManager.log(event: .tokenDetailsSendClick)
            analyticsManager.log(event: .sendViewed(lastScreen: "token_details"))
            navigatableSceneSubject = .send(wallet: wallet)
        }

        private func buyTokens() {
            var tokens = Buy.CryptoCurrency.sol
            if symbol == "SOL" {
                tokens = .sol
            }
            print(symbol)
            if symbol == "USDC" {
                tokens = .usdc
            }
            analyticsManager.log(event: .tokenDetailsBuyClick)
            navigatableSceneSubject = .buy(tokens: tokens)
        }

        private func receiveTokens() {
            guard let pubkey = walletSubject?.pubkey else { return }
            analyticsManager.log(event: .tokenDetailQrClick)
            analyticsManager.log(event: .tokenReceiveViewed)
            analyticsManager.log(event: .receiveViewed(fromPage: "token_details"))
            navigatableSceneSubject = .receive(walletPubkey: pubkey)
        }

        private func swapTokens() {
            guard let wallet = walletSubject else { return }
            analyticsManager.log(event: .tokenDetailsSwapClick)
            analyticsManager.log(event: .swapViewed(lastScreen: "token_details"))
            navigatableSceneSubject = .swap(fromWallet: wallet)
        }
    }
}

extension WalletDetail.ViewModel: WalletDetailViewModelType {
    var walletActionsPublisher: AnyPublisher<[WalletActionType], Never> {
        $walletSubject
            .map { wallet -> [WalletActionType] in
                guard let wallet = wallet else { return [] }

                if wallet.isNativeSOL || wallet.token.symbol == "USDC" {
                    return [.buy, .receive, .send, .swap]
                } else {
                    return [.receive, .send, .swap]
                }
            }
            .eraseToAnyPublisher()
    }

    var navigatableScenePublisher: AnyPublisher<WalletDetail.NavigatableScene?, Never> {
        $navigatableSceneSubject.eraseToAnyPublisher()
    }

    var walletPublisher: AnyPublisher<Wallet?, Never> {
        $walletSubject.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func showWalletSettings() {
        guard let pubkey = walletSubject?.pubkey else { return }
        navigatableSceneSubject = .settings(walletPubkey: pubkey)
    }

    func start(action: WalletActionType) {
        switch action {
        case .receive:
            receiveTokens()
        case .buy:
            buyTokens()
        case .send:
            sendTokens()
        case .swap:
            swapTokens()
        }
    }

    func showTransaction(_ transaction: ParsedTransaction) {
        analyticsManager.log(event: .tokenDetailsDetailsOpen)
        navigatableSceneSubject = .transactionInfo(transaction)
    }
}
