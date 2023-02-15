//
//  WalletDetail.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import AnalyticsManager
import Foundation
import Resolver
import Combine
import SolanaSwift
import TransactionParser

protocol WalletDetailViewModelType {
    var walletsRepository: WalletsRepository { get }
    var navigatableScenePublisher: AnyPublisher<WalletDetail.NavigatableScene?, Never> { get }
    var walletPublisher: AnyPublisher<Wallet?, Never> { get }
    var walletActionsPublisher: AnyPublisher<[WalletActionType], Never> { get }

    func start(action: WalletActionType)
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

        private var subscriptions = Set<AnyCancellable>()

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
        @Published private var wallet: Wallet?
        private lazy var walletActionsSubject = $wallet
            .map { wallet -> [WalletActionType] in
                guard let wallet = wallet else { return [] }

                if wallet.isNativeSOL || wallet.token.symbol == "USDC" {
                    return [.buy, .receive, .send, .swap]
                } else {
                    return [.receive, .send, .swap]
                }
            }

        // MARK: - Initializer

        init(pubkey: String, symbol: String) {
            self.pubkey = pubkey
            self.symbol = symbol
            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        /// Bind subjects
        private func bind() {
            bindSubjectsIntoSubjects()
        }

        private func bindSubjectsIntoSubjects() {
            walletsRepository
                .dataPublisher
                .receive(on: DispatchQueue.main)
                .map { [weak self] in $0.first(where: { $0.pubkey == self?.pubkey }) }
                .filter { $0 != nil }
                .assign(to: \.wallet, on: self)
                .store(in: &subscriptions)

            $wallet
                .filter { $0 != nil }
                .map { $0!.token.symbol }
                .prefix(1)
                .sink { [weak self] ticker in
                    self?.analyticsManager.log(event: .tokenDetailsOpen(tokenTicker: ticker))
                }
                .store(in: &subscriptions)
        }

        private func sendTokens() {
            guard let wallet else { return }
            analyticsManager.log(event: .tokenDetailsSendClick)
            analyticsManager.log(event: .sendViewed(lastScreen: "token_details"))
            navigatableScene = .send(wallet: wallet)
        }

        private func buyTokens() {
            var tokens = Buy.CryptoCurrency.sol
            if symbol == "SOL" {
                tokens = .sol
            }

            if symbol == "USDC" {
                tokens = .usdc
            }
            analyticsManager.log(event: .tokenDetailsBuyClick)
            navigatableScene = .buy(tokens: tokens)
        }

        private func receiveTokens() {
            guard let pubkey = wallet?.pubkey else { return }
            analyticsManager.log(event: .tokenDetailQrClick)
            analyticsManager.log(event: .tokenReceiveViewed)
            analyticsManager.log(event: .receiveViewed(fromPage: "token_details"))
            navigatableScene = .receive(walletPubkey: pubkey)
        }

        private func swapTokens() {
            guard let wallet else { return }
            analyticsManager.log(event: .tokenDetailsSwapClick)
            analyticsManager.log(event: .swapViewed(lastScreen: "token_details"))
            navigatableScene = .swap(fromWallet: wallet)
        }

        private func cashOut() {
            navigatableScene = .cashOut
        }
    }
}

extension WalletDetail.ViewModel: WalletDetailViewModelType {
    var walletActionsPublisher: AnyPublisher<[WalletActionType], Never> {
        walletActionsSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var navigatableScenePublisher: AnyPublisher<WalletDetail.NavigatableScene?, Never> {
        $navigatableScene
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var walletPublisher: AnyPublisher<Wallet?, Never> {
        $wallet
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Actions

    func start(action: WalletActionType) {
        switch action {
        case .receive:
            receiveTokens()
        case .buy:
            buyTokens()
        case .send:
            analyticsManager.log(event: .actionPanelSendToken(tokenName: symbol))
            sendTokens()
        case .swap:
            analyticsManager.log(event: .actionPanelSwapToken(tokenName: symbol))
            swapTokens()
        case .cashOut:
            cashOut()
        }
    }
}
