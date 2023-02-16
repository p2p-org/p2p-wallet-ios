//
//  DAppContainer.ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import Foundation
import Resolver
import Combine
import SolanaSwift
import WebKit

protocol DAppContainerViewModelType {
    var navigationPublisher: AnyPublisher<DAppContainer.NavigatableScene?, Never> { get }
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

        private let navigationSubject = CurrentValueSubject<NavigatableScene?, Never>(nil)

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
    var navigationPublisher: AnyPublisher<DAppContainer.NavigatableScene?, Never> {
        navigationSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    // MARK: - Actions

    func navigate(to scene: DAppContainer.NavigatableScene) {
        navigationSubject.send(scene)
    }

    func getWebviewConfiguration() -> WKWebViewConfiguration {
        dAppChannel.getWebviewConfiguration()
    }

    func getDAppURL() -> String {
        dapp.url
    }
}

extension DAppContainer.ViewModel: DAppChannelDelegate {
    func connect() -> AnyPublisher<String, Error> {
        guard let pubKey = walletsRepository.getWallets().first(where: { $0.isNativeSOL })?.pubkey else {
            return Fail(error: DAppChannelError.canNotFindWalletAddress)
                .eraseToAnyPublisher()
        }

        return Just(pubKey).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func signTransaction(transaction: Transaction) -> AnyPublisher<Transaction, Error> {
        do {
            var transaction = transaction
            guard let signer = accountStorage.account
            else { throw DAppChannelError.unauthorized }

            try transaction.sign(signers: [signer])
            return Just(transaction).setFailureType(to: Error.self).eraseToAnyPublisher()
        } catch let e {
            return Fail(error: e).eraseToAnyPublisher()
        }
    }

    func signTransactions(transactions: [Transaction]) -> AnyPublisher<[Transaction], Error> {
        do {
            return Just(try transactions.map { transaction in
                var transaction = transaction
                guard let signer = accountStorage.account
                else { throw DAppChannelError.unauthorized }

                try transaction.sign(signers: [signer])
                return transaction
            })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch let e {
            return Fail(error: e).eraseToAnyPublisher()
        }
    }
}
