//
//  DAppContainer.ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import Combine
import Foundation
import Resolver
import SolanaSwift
import WebKit

protocol DAppContainerViewModelType {
    var navigationAnyPublisher: AnyPublisher<DAppContainer.NavigatableScene?, Never> { get }
    func navigate(to scene: DAppContainer.NavigatableScene)

    func getWebviewConfiguration() -> WKWebViewConfiguration
    func getDAppURL() -> String
}

extension DAppContainer {
    @MainActor
    class ViewModel: NSObject, ObservableObject {
        // MARK: - Dependencies

        @Injected private var dAppChannel: DAppChannel
        @Injected private var accountStorage: SolanaAccountStorage
        @Injected private var walletsRepository: WalletsRepository

        // MARK: - Properties

        private let dapp: DApp

        // MARK: - Subject

        @Published private var navigationSubject: NavigatableScene?

        init(dapp: DApp) {
            self.dapp = dapp
            super.init()
            dAppChannel.setDelegate(self)
        }

        deinit {
            print("\(String(describing: self)) deinited")
        }
    }
}

extension DAppContainer.ViewModel: DAppContainerViewModelType {
    var navigationAnyPublisher: AnyPublisher<DAppContainer.NavigatableScene?, Never> {
        $navigationSubject.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func navigate(to scene: DAppContainer.NavigatableScene) {
        navigationSubject = scene
    }

    func getWebviewConfiguration() -> WKWebViewConfiguration {
        dAppChannel.getWebviewConfiguration()
    }

    func getDAppURL() -> String {
        dapp.url
    }
}

extension DAppContainer.ViewModel: DAppChannelDelegate {
    func connect() async throws -> String {
        guard let pubKey = walletsRepository.getWallets().first(where: { $0.isNativeSOL })?.pubkey else {
            throw DAppChannelError.canNotFindWalletAddress
        }

        return pubKey
    }

    func signTransaction(transaction: Transaction) async throws -> Transaction {
        var transaction = transaction
        guard let signer = accountStorage.account
        else { throw DAppChannelError.unauthorized }

        try transaction.sign(signers: [signer])
        return transaction
    }

    func signTransactions(transactions: [Transaction]) async throws -> [Transaction] {
        try transactions.map { transaction in
            var transaction = transaction
            guard let signer = accountStorage.account
            else { throw DAppChannelError.unauthorized }

            try transaction.sign(signers: [signer])
            return transaction
        }
    }
}
