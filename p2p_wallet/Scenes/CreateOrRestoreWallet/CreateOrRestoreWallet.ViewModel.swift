//
//  CreateOrRestoreWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Resolver
import RxCocoa
import RxSwift
import UIKit

protocol CreateOrRestoreWalletViewModelType {
    var navigatableSceneDriver: Driver<CreateOrRestoreWallet.NavigatableScene?> { get }

    func navigateToCreateWalletScene()
    func navigateToRestoreWalletScene()
}

extension CreateOrRestoreWallet {
    class ViewModel {
        // MARK: - Dependencies

        @Injected var analyticsManager: AnalyticsManagerType

        // MARK: - Initializer

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        // MARK: - Subjects

        private let navigatableSceneSubject = BehaviorRelay<CreateOrRestoreWallet.NavigatableScene?>(value: nil)
    }
}

extension CreateOrRestoreWallet.ViewModel: CreateOrRestoreWalletViewModelType {
    var navigatableSceneDriver: Driver<CreateOrRestoreWallet.NavigatableScene?> {
        navigatableSceneSubject.asDriver()
    }

    // MARK: - Actions

    func navigateToCreateWalletScene() {
        analyticsManager.log(event: .splashCreating)
        navigatableSceneSubject.accept(.createWallet)
    }

    func navigateToRestoreWalletScene() {
        analyticsManager.log(event: .splashRestoring)
        analyticsManager.log(event: .recoveryOpen(fromPage: "first_in"))
        navigatableSceneSubject.accept(.restoreWallet)
    }
}
