//
//  CreateWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import AnalyticsManager
import Combine
import Resolver
import SolanaSwift
import UIKit

protocol CreateWalletViewModelType {
    var navigatableScenePublisher: AnyPublisher<CreateWallet.NavigatableScene?, Never> { get }

    func kickOff()
    func verifyPhrase(_ phrases: [String])
    func handlePhrases(_ phrases: [String]) async
    func navigateToCreatePhrases()
    func back()
}

extension CreateWallet {
    class ViewModel: BaseViewModel, CreateWalletViewModelType {
        // MARK: - Dependencies

        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var analyticsManager: AnalyticsManager

        // MARK: - Properties

        private var phrases: [String]?

        // MARK: - Subjects

        @Published private var navigatableScene: CreateWallet.NavigatableScene?

        var navigatableScenePublisher: AnyPublisher<CreateWallet.NavigatableScene?, Never> {
            $navigatableScene.eraseToAnyPublisher()
        }

        func kickOff() {
            navigatableScene = .explanation
        }

        func verifyPhrase(_ phrases: [String]) {
            navigatableScene = .verifyPhrase(phrases)
        }

        func handlePhrases(_ phrases: [String]) async {
            self.phrases = phrases
            finish()
        }

        private func finish() {
            navigatableScene = .dismiss
            handler.creatingWalletDidComplete(
                phrases: phrases,
                derivablePath: .default,
                name: nil
            )
        }

        func navigateToCreatePhrases() {
            analyticsManager.log(event: AmplitudeEvent.createSeedInvoked)
            navigatableScene = .createPhrases
        }

        func back() {
            navigatableScene = .back
            navigatableScene = .none
        }
    }
}
