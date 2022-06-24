//
//  DAppContainer.ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift
import WebKit

protocol DAppContainerViewModelType {
    var navigationDriver: Driver<DAppContainer.NavigatableScene?> { get }
    func navigate(to scene: DAppContainer.NavigatableScene)

    func getWebviewConfiguration() -> WKWebViewConfiguration
    func getDAppURL() -> String
}

extension DAppContainer {
    class ViewModel: NSObject {
        // MARK: - Dependencies

        @Injected private var dAppChannel: DAppChannel
        @Injected private var accountStorage: SolanaAccountStorage
        @Injected private var walletsRepository: WalletsRepository

        // MARK: - Properties

        private let dapp: DApp

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)

        init(dapp: DApp) {
            self.dapp = dapp
            super.init()
            dAppChannel.setDelegate(self)
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension DAppContainer.ViewModel: DAppContainerViewModelType {
    var navigationDriver: Driver<DAppContainer.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    // MARK: - Actions

    func navigate(to scene: DAppContainer.NavigatableScene) {
        navigationSubject.accept(scene)
    }

    func getWebviewConfiguration() -> WKWebViewConfiguration {
        dAppChannel.getWebviewConfiguration()
    }

    func getDAppURL() -> String {
        dapp.url
    }
}

extension DAppContainer.ViewModel: DAppChannelDelegate {
    func connect() -> Single<String> {
        guard let pubKey = walletsRepository.getWallets().first(where: { $0.isNativeSOL })?.pubkey else {
            return .error(DAppChannelError.canNotFindWalletAddress)
        }

        return .just(pubKey)
    }

    func signTransaction(transaction: Transaction) -> Single<Transaction> {
        do {
            var transaction = transaction
            guard let signer = accountStorage.account
            else { throw DAppChannelError.unauthorized }

            try transaction.sign(signers: [signer])
            return .just(transaction)
        } catch let e {
            return .error(e)
        }
    }

    func signTransactions(transactions: [Transaction]) -> Single<[Transaction]> {
        do {
            return .just(try transactions.map { transaction in
                var transaction = transaction
                guard let signer = accountStorage.account
                else { throw DAppChannelError.unauthorized }

                try transaction.sign(signers: [signer])
                return transaction
            })
        } catch let e {
            return .error(e)
        }
    }
}
