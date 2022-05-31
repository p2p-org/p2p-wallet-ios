//
//  CreateWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Resolver
import RxCocoa
import RxSwift
import SolanaSwift
import UIKit

protocol CreateWalletViewModelType: ReserveNameHandler {
    var navigatableSceneDriver: Driver<CreateWallet.NavigatableScene?> { get }

    func kickOff()
    func verifyPhrase(_ phrases: [String])
    func handlePhrases(_ phrases: [String])
    func handleName(_ name: String?)

    func navigateToCreatePhrases()
    func back()
}

extension CreateWallet {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var notificationsService: NotificationService

        // MARK: - Properties

        private var phrases: [String]?
        private var name: String?

        // MARK: - Subjects

        private let navigationSubject = BehaviorRelay<CreateWallet.NavigatableScene?>(value: nil)

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension CreateWallet.ViewModel: CreateWalletViewModelType {
    var navigatableSceneDriver: Driver<CreateWallet.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    // MARK: - Actions

    func kickOff() {
        analyticsManager.log(event: .createWalletOpen)
        navigateToExplanation()
    }

    func verifyPhrase(_ phrases: [String]) {
        navigationSubject.accept(.verifyPhrase(phrases))
    }

    func handlePhrases(_ phrases: [String]) {
        self.phrases = phrases

        UIApplication.shared.showIndetermineHud()

        Task {
            do {
                let account = try await Account(
                    phrase: phrases,
                    network: Defaults.apiEndPoint.network,
                    derivablePath: .default
                )

                await MainActor.run { [weak self] in
                    UIApplication.shared.hideHud()
                    self?.navigateToReserveName(owner: account.publicKey.base58EncodedString)
                }
            } catch {
                await MainActor.run { [weak self] in
                    UIApplication.shared.hideHud()
                    self?.notificationsService.showInAppNotification(.error(error))
                }
            }
        }
    }

    func handleName(_ name: String?) {
        self.name = name
        finish()
    }

    func finish() {
        navigationSubject.accept(.dismiss)
        handler.creatingWalletDidComplete(
            phrases: phrases,
            derivablePath: .default,
            name: name
        )
    }

    func navigateToExplanation() {
        navigationSubject.accept(.explanation)
    }

    func back() {
        navigationSubject.accept(.back)
        navigationSubject.accept(.none)
    }

    func navigateToCreatePhrases() {
        analyticsManager.log(event: .createSeedInvoked)
        navigationSubject.accept(.createPhrases)
    }

    func navigateToReserveName(owner: String) {
        navigationSubject.accept(.reserveName(owner: owner))
    }
}
