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

protocol CreateWalletViewModelType: ReserveNameHandler {
    var navigatableScenePublisher: AnyPublisher<CreateWallet.NavigatableScene?, Never> { get }

    func kickOff()
    func verifyPhrase(_ phrases: [String])
    func handlePhrases(_ phrases: [String]) async
    func handleName(_ name: String?)

    func navigateToCreatePhrases()
    func back()
}

extension CreateWallet {
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var notificationsService: NotificationService

        // MARK: - Properties

        private var phrases: [String]?
        private var name: String?

        // MARK: - Subjects

        @Published private var navigationSubject: CreateWallet.NavigatableScene?
    }
}

extension CreateWallet.ViewModel: CreateWalletViewModelType {
    var navigatableScenePublisher: AnyPublisher<CreateWallet.NavigatableScene?, Never> {
        $navigationSubject.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func kickOff() {
        navigateToExplanation()
    }

    func verifyPhrase(_ phrases: [String]) {
        navigationSubject = .verifyPhrase(phrases)
    }

    func handlePhrases(_ phrases: [String]) async {
        self.phrases = phrases

        UIApplication.shared.showIndetermineHud()

        do {
            let account = try await Account(
                phrase: phrases,
                network: Defaults.apiEndPoint.network,
                derivablePath: .default
            )

            navigateToReserveName(owner: account.publicKey.base58EncodedString)
        } catch {
            notificationsService.showInAppNotification(.error(error))
        }
        UIApplication.shared.hideHud()
    }

    func handleName(_ name: String?) {
        self.name = name
        finish()
    }

    func finish() {
        navigationSubject = .dismiss
        handler.creatingWalletDidComplete(
            phrases: phrases,
            derivablePath: .default,
            name: name
        )
    }

    func navigateToExplanation() {
        navigationSubject = .explanation
    }

    func back() {
        navigationSubject = .back
        navigationSubject = .none
    }

    func navigateToCreatePhrases() {
        analyticsManager.log(event: .createSeedInvoked)
        navigationSubject = .createPhrases
    }

    func navigateToReserveName(owner: String) {
        navigationSubject = .reserveName(owner: owner)
    }
}
