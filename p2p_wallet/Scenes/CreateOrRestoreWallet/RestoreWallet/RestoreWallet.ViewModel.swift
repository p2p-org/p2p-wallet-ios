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
    var navigatableSceneDriver: AnyPublisher<RestoreWallet.NavigatableScene?, Never> { get }
    var isLoadingDriver: AnyPublisher<Bool, Never> { get }
    var isRestorableUsingIcloud: AnyPublisher<Bool, Never> { get }
    var errorSignal: AnyPublisher<String, Never> { get }

    func handleICloudAccount(_ account: RawAccount)
    func restoreFromICloud()
    func restoreManually()
}

extension RestoreWallet {
    @MainActor
    class ViewModel: ObservableObject {
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

        @Published private var navigationSubject: RestoreWallet.NavigatableScene?
        @Published private var isLoadingSubject = false
        @Published private var isRestorableUsingIcloudSubject = false
        private let errorSubject = PassthroughSubject<String, Never>()
        private let finishedSubject = PassthroughSubject<Void, Never>()

        deinit {
            print("\(String(describing: self)) deinited")
        }
    }
}

extension RestoreWallet.ViewModel: RestoreWalletViewModelType {
    var isRestorableUsingIcloud: AnyPublisher<Bool, Never> {
        $isRestorableUsingIcloudSubject.eraseToAnyPublisher()
    }

    var navigatableSceneDriver: AnyPublisher<RestoreWallet.NavigatableScene?, Never> {
        $navigationSubject.eraseToAnyPublisher()
    }

    var isLoadingDriver: AnyPublisher<Bool, Never> {
        $isLoadingSubject.eraseToAnyPublisher()
    }

    var errorSignal: AnyPublisher<String, Never> {
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
        navigationSubject = .restoreFromICloud
    }

    func restoreManually() {
        analyticsManager.log(event: .restoreManualInvoked)
        navigationSubject = .enterPhrases
    }

    func handlePhrases(_ phrases: [String], derivablePath: DerivablePath?) {
        self.phrases = phrases
        if let derivablePath = derivablePath {
            derivablePathDidSelect(derivablePath, phrases: phrases)
        } else {
            navigationSubject = .derivableAccounts(phrases: phrases)
        }
    }

    @MainActor
    func handleICloudAccount(_ account: RawAccount) {
        phrases = account.phrase.components(separatedBy: " ")
        derivablePath = account.derivablePath
        if let name = account.name {
            self.name = name
            finish()
        } else {
            // create account
            isLoadingSubject = true
            guard let phrases = phrases else { return }
            Task {
                do {
                    let account = try await Account(
                        phrase: phrases,
                        network: Defaults.apiEndPoint.network,
                        derivablePath: derivablePath
                    )
                    // reserve name
                    isLoadingSubject = false
                    navigationSubject = .reserveName(owner: account.publicKey.base58EncodedString)
                } catch {
                    errorSubject.send(error.readableDescription)
                }
            }
        }
    }
}

// MARK: - AccountRestorationHandler

extension RestoreWallet.ViewModel {
    func derivablePathDidSelect(_ derivablePath: DerivablePath, phrases: [String]) {
        analyticsManager.log(event: .recoveryRestoreClick)
        self.derivablePath = derivablePath
        self.phrases = phrases

        // create account
        isLoadingSubject = true

        Task {
            do {
                let account = try await Account(
                    phrase: phrases,
                    network: Defaults.apiEndPoint.network,
                    derivablePath: derivablePath
                )

                let owner = account.publicKey.base58EncodedString

                // check if name available
                do {
                    let name = try await nameService.getName(owner)

                    isLoadingSubject = false

                    // save to icloud
                    saveToICloud(name: name, phrase: phrases, derivablePath: derivablePath)

                    if let name = name {
                        handleName(name)
                    } else {
                        navigationSubject = .reserveName(owner: owner)
                    }
                } catch {
                    isLoadingSubject = false

                    // save to icloud
                    saveToICloud(name: nil, phrase: phrases, derivablePath: derivablePath)

                    finish()
                }
            } catch {
                errorSubject.send(error.readableDescription)
            }
        }

        DispatchQueue(label: "Create account", qos: .userInteractive).async {}
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
