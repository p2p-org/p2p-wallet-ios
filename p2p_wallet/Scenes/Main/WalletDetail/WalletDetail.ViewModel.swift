//
//  WalletDetail.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import AnalyticsManager
import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift
import TransactionParser

protocol WalletDetailViewModelType {
    var walletsRepository: WalletsRepository { get }
    var navigatableSceneDriver: Driver<WalletDetail.NavigatableScene?> { get }
    var walletDriver: Driver<Wallet?> { get }
    var walletActionsDriver: Driver<[WalletActionType]> { get }

    func start(action: WalletActionType)
    func showTransaction(_ transaction: ParsedTransaction)
    var pubkey: String { get }
    var symbol: String { get }
}

extension WalletDetail {
    class ViewModel {
        // MARK: - Dependencies

        @Injected var walletsRepository: WalletsRepository
        let pubkey: String
        let symbol: String
        @Injected var analyticsManager: AnalyticsManager

        // MARK: - Properties

        private let disposeBag = DisposeBag()

        // MARK: - Subject

        private let navigatableSceneSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        private lazy var walletActionsSubject = walletSubject
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
                .map(Optional.init)
                .map { [weak self] in $0?.first(where: { $0.pubkey == self?.pubkey }) }
                .replaceError(with: nil)
                .filter { $0 != nil }
                .asObservable()
                .bind(to: walletSubject)
                .disposed(by: disposeBag)

            walletSubject
                .filter { $0 != nil }
                .map { $0!.token.symbol }
                .take(1)
                .asSingle()
                .subscribe(onSuccess: { [weak self] ticker in
                    self?.analyticsManager.log(event: .tokenDetailsOpen(tokenTicker: ticker))
                })
                .disposed(by: disposeBag)
        }

        private func sendTokens() {
            guard let wallet = walletSubject.value else { return }
            analyticsManager.log(event: .tokenDetailsSendClick)
            analyticsManager.log(event: .sendViewed(lastScreen: "token_details"))
            navigatableSceneSubject.accept(.send(wallet: wallet))
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
            navigatableSceneSubject.accept(.buy(tokens: tokens))
        }

        private func receiveTokens() {
            guard let pubkey = walletSubject.value?.pubkey else { return }
            analyticsManager.log(event: .tokenDetailQrClick)
            analyticsManager.log(event: .tokenReceiveViewed)
            analyticsManager.log(event: .receiveViewed(fromPage: "token_details"))
            navigatableSceneSubject.accept(.receive(walletPubkey: pubkey))
        }

        private func swapTokens() {
            guard let wallet = walletSubject.value else { return }
            analyticsManager.log(event: .tokenDetailsSwapClick)
            analyticsManager.log(event: .swapViewed(lastScreen: "token_details"))
            navigatableSceneSubject.accept(.swap(fromWallet: wallet))
        }

        private func cashOut() {
            navigatableSceneSubject.accept(.cashOut)
        }
    }
}

extension WalletDetail.ViewModel: WalletDetailViewModelType {
    var walletActionsDriver: Driver<[WalletActionType]> {
        walletActionsSubject
            .asDriver(onErrorJustReturn: [])
    }

    var navigatableSceneDriver: Driver<WalletDetail.NavigatableScene?> {
        navigatableSceneSubject.asDriver()
    }

    var walletDriver: Driver<Wallet?> {
        walletSubject.asDriver()
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

    func showTransaction(_ transaction: ParsedTransaction) {
        analyticsManager.log(event: .tokenDetailsDetailsOpen)
        navigatableSceneSubject.accept(.transactionInfo(transaction))
    }
}
