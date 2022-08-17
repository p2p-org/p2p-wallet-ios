//
//  RestoreWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import AnalyticsManager
import Combine
import NameService
import Resolver
import SolanaSwift
import UIKit

protocol RestoreWalletViewModelType: ReserveNameHandler, AccountRestorationHandler {
    var navigatableScenePublisher: AnyPublisher<RestoreWallet.NavigatableScene?, Never> { get }
    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }
    var isRestorableUsingIcloud: AnyPublisher<Bool, Never> { get }
    var errorPublisher: AnyPublisher<String, Never> { get }

    func handleICloudAccount(_ account: RawAccount)
    func restoreFromICloud()
    func restoreManually()
}

extension RestoreWallet {
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var iCloudStorage: ICloudStorageType
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var nameService: NameService
        @Injected private var deviceOwnerAuthenticationHandler: DeviceOwnerAuthenticationHandler
        @Injected private var notificationsService: NotificationService

        // MARK: - Properties

        private var phrases: [String]?
        private var derivablePath: DerivablePath?
        private var name: String?

        // MARK: - Subjects

        @Published private var navigatableScene: RestoreWallet.NavigatableScene?
        @Published private var isLoadingSubject = false
        @Published private var isRestorableUsingIcloudSubject = false
        private let errorSubject = PassthroughSubject<String, Never>()
        private let finishedSubject = PassthroughSubject<Void, Never>()
    }
}

extension RestoreWallet.ViewModel: RestoreWalletViewModelType {
    var isRestorableUsingIcloud: AnyPublisher<Bool, Never> {
        $isRestorableUsingIcloudSubject.eraseToAnyPublisher()
    }

    var navigatableScenePublisher: AnyPublisher<RestoreWallet.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        $isLoadingSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func restoreFromICloud() {
        deviceOwnerAuthenticationHandler.requiredOwner {
            self._restoreFromIcloud()
        } onFailure: { error in
            guard let error = error else { return }
            self.errorSubject.send(error)
        }
    }

    private func _restoreFromIcloud() {
        guard let accounts = iCloudStorage.accountFromICloud(), !accounts.isEmpty
        else {
            isRestorableUsingIcloudSubject = false
            notificationsService.showInAppNotification(.message(L10n.thereIsNoP2PWalletSavedInYourICloud))
            return
        }
        analyticsManager.log(event: .restoreAppleInvoked)

        // if there is only 1 account saved in iCloud
        if accounts.count == 1 {
            handlePhrases(accounts[0].phrase.components(separatedBy: " "), derivablePath: accounts[0].derivablePath)
            return
        }

        // if there are more than 1 account saved in iCloud
        navigatableScene = .restoreFromICloud
    }

    func restoreManually() {
        analyticsManager.log(event: .restoreManualInvoked)
        navigatableScene = .enterPhrases
    }

    func handlePhrases(_ phrases: [String], derivablePath: DerivablePath?) {
        self.phrases = phrases
        if let derivablePath = derivablePath {
            derivablePathDidSelect(derivablePath, phrases: phrases)
        } else {
            navigatableScene = .derivableAccounts(phrases: phrases)
        }
    }

    @MainActor
    func handleICloudAccount(_ account: RawAccount) {
        phrases = account.phrase.components(separatedBy: " ")
        derivablePath = account.derivablePath
        name = account.name
        finish()
    }
}

// MARK: - AccountRestorationHandler

extension RestoreWallet.ViewModel {
    func derivablePathDidSelect(_ derivablePath: DerivablePath, phrases: [String]) {
        analyticsManager.log(event: .recoveryRestoreClick)
        self.derivablePath = derivablePath
        self.phrases = phrases

        // save to icloud
        saveToICloud(name: nil, phrase: phrases, derivablePath: derivablePath)
        notificationsService.showInAppNotification(.done(L10n.savedToICloud))
        finish()
    }

    @MainActor
    private func saveToICloud(name: String?, phrase: [String], derivablePath: DerivablePath) {
        _ = iCloudStorage.saveToICloud(
            account: .init(
                name: name,
                phrase: phrase.joined(separator: " "),
                derivablePath: derivablePath
            )
        )
        notificationsService.showInAppNotification(.done(L10n.savedToICloud))
    }
}

extension RestoreWallet.ViewModel: ReserveNameHandler {
    @MainActor
    func handleName(_ name: String?) {
        self.name = name
        finish()
    }
}

private extension RestoreWallet.ViewModel {
    @MainActor
    func finish() {
        finishedSubject.send()
        handler.restoringWalletDidComplete(
            phrases: phrases,
            derivablePath: derivablePath,
            name: name
        )
    }
}
