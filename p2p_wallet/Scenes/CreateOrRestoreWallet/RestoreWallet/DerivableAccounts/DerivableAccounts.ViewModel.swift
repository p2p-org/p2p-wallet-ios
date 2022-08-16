//
//  DerivableAccounts.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Combine
import Foundation
import SolanaSwift

protocol AccountRestorationHandler {
    func derivablePathDidSelect(_ derivablePath: DerivablePath, phrases: [String])
}

protocol DrivableAccountsViewModelType {
    var accountsListViewModel: DerivableAccountsListViewModelType { get }
    var navigatableScenePublisher: AnyPublisher<DerivableAccounts.NavigatableScene?, Never> { get }
    var selectedDerivablePathPublisher: AnyPublisher<DerivablePath, Never> { get }

    func getCurrentSelectedDerivablePath() -> DerivablePath
    func chooseDerivationPath()
    func selectDerivationPath(_ path: DerivablePath)
    func restoreAccount()
}

extension DerivableAccounts {
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        private let handler: AccountRestorationHandler

        // MARK: - Properties

        private let phrases: [String]
        let accountsListViewModel: DerivableAccountsListViewModelType

        // MARK: - Subjects

        @Published private var navigatableScene: NavigatableScene?
        @Published private var selectedDerivablePath = DerivablePath.default

        // MARK: - Initializer

        init(phrases: [String], handler: AccountRestorationHandler) {
            self.phrases = phrases
            self.handler = handler
            accountsListViewModel = ListViewModel(phrases: phrases)
        }
    }
}

extension DerivableAccounts.ViewModel: DrivableAccountsViewModelType {
    var navigatableScenePublisher: AnyPublisher<DerivableAccounts.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var selectedDerivablePathPublisher: AnyPublisher<DerivablePath, Never> {
        $selectedDerivablePath.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func getCurrentSelectedDerivablePath() -> DerivablePath {
        selectedDerivablePath
    }

    func chooseDerivationPath() {
        navigatableScene = .selectDerivationPath
    }

    func selectDerivationPath(_ path: DerivablePath) {
        selectedDerivablePath = path
    }

    func restoreAccount() {
        // cancel any requests
        accountsListViewModel.cancelRequest()

        // send to handler
        handler.derivablePathDidSelect(selectedDerivablePath, phrases: phrases)
    }
}
