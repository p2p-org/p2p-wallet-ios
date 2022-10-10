//
//  DerivableAccounts.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

protocol AccountRestorationHandler {
    func derivablePathDidSelect(_ derivablePath: DerivablePath, phrases: [String])
}

protocol DrivableAccountsViewModelType {
    var accountsListViewModel: DerivableAccountsListViewModelType { get }
    var navigatableSceneDriver: Driver<DerivableAccounts.NavigatableScene?> { get }
    var selectedDerivablePathDriver: Driver<DerivablePath> { get }

    func getCurrentSelectedDerivablePath() -> DerivablePath
    func chooseDerivationPath()
    func selectDerivationPath(_ path: DerivablePath)
    func restoreAccount()
}

extension DerivableAccounts {
    class ViewModel {
        // MARK: - Dependencies

        private let handler: AccountRestorationHandler

        // MARK: - Properties

        private let phrases: [String]
        let accountsListViewModel: DerivableAccountsListViewModelType

        // MARK: - Subjects

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let selectedDerivablePathSubject = BehaviorRelay<DerivablePath>(value: .default)

        // MARK: - Initializer

        init(phrases: [String], handler: AccountRestorationHandler) {
            self.phrases = phrases
            self.handler = handler
            accountsListViewModel = ListViewModel(phrases: phrases)
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension DerivableAccounts.ViewModel: DrivableAccountsViewModelType {
    var navigatableSceneDriver: Driver<DerivableAccounts.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var selectedDerivablePathDriver: Driver<DerivablePath> {
        selectedDerivablePathSubject.asDriver()
    }

    // MARK: - Actions

    func getCurrentSelectedDerivablePath() -> DerivablePath {
        selectedDerivablePathSubject.value
    }

    func chooseDerivationPath() {
        navigationSubject.accept(.selectDerivationPath)
    }

    func selectDerivationPath(_ path: DerivablePath) {
        selectedDerivablePathSubject.accept(path)
    }

    func restoreAccount() {
        // cancel any requests
        accountsListViewModel.cancelRequest()

        // send to handler
        handler.derivablePathDidSelect(selectedDerivablePathSubject.value, phrases: phrases)
    }
}
