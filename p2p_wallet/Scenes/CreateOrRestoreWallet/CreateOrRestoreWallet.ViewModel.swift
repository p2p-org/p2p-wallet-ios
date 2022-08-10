//
//  CreateOrRestoreWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import AnalyticsManager
import Combine
import Resolver
import UIKit

protocol CreateOrRestoreWalletViewModelType {
    var navigatableScenePublisher: AnyPublisher<CreateOrRestoreWallet.NavigatableScene?, Never> { get }

    func navigateToCreateWalletScene()
    func navigateToRestoreWalletScene()
}

extension CreateOrRestoreWallet {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        @Injected var analyticsManager: AnalyticsManager

        // MARK: - Subjects

        @Published private var navigatableScene: CreateOrRestoreWallet.NavigatableScene?

        // MARK: - Initializer

        deinit {
            print("\(String(describing: self)) deinited")
        }
    }
}

extension CreateOrRestoreWallet.ViewModel: CreateOrRestoreWalletViewModelType {
    var navigatableScenePublisher: AnyPublisher<CreateOrRestoreWallet.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func navigateToCreateWalletScene() {
        analyticsManager.log(event: .splashCreating)
        navigatableScene = .createWallet
        OnboardingTracking.currentFlow = .create
    }

    func navigateToRestoreWalletScene() {
        analyticsManager.log(event: .splashRestoring)
        analyticsManager.log(event: .recoveryOpen(fromPage: "first_in"))
        navigatableScene = .restoreWallet
        OnboardingTracking.currentFlow = .restore
    }
}
