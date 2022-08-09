//
//  CreateSecurityKeys.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import AnalyticsManager
import Combine
import Resolver
import SolanaSwift
import UIKit

protocol CreateSecurityKeysViewModelType: AnyObject {
    var showTermsAndConditionsSignal: AnyPublisher<Void, Never> { get }
    var showPhotoLibraryUnavailableSignal: AnyPublisher<Void, Never> { get }
    var phrasesDriver: AnyPublisher<[String], Never> { get }
    var errorSignal: AnyPublisher<String, Never> { get }

    func copyToClipboard()
    func renewPhrases()

    func saveToICloud()
    func back()
    func verifyPhrase()
    func termsAndConditions()
    func saveKeysImage(_: UIImage)
}

extension CreateSecurityKeys {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        @Injected private var iCloudStorage: ICloudStorageType
        @Injected private var analyticsManager: AnalyticsManager
        private let createWalletViewModel: CreateWalletViewModelType
        @Injected private var deviceOwnerAuthenticationHandler: DeviceOwnerAuthenticationHandler
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationsService: NotificationService
        @Injected var imageSaver: ImageSaverType

        // MARK: - Subjects

        private let showTermsAndConditionsSubject = PassthroughSubject<Void, Never>()
        private let showPhotoLibraryUnavailableSubject = PassthroughSubject<Void, Never>()
        @Published private var phrases = [String]()
        private let errorSubject = PassthroughSubject<String, Never>()

        // MARK: - Initializer

        init(createWalletViewModel: CreateWalletViewModelType) {
            self.createWalletViewModel = createWalletViewModel
            createPhrases()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        private func createPhrases() {
            let mnemonic = Mnemonic()
            phrases = mnemonic.phrase
        }
    }
}

extension CreateSecurityKeys.ViewModel: CreateSecurityKeysViewModelType {
    var showPhotoLibraryUnavailableSignal: AnyPublisher<Void, Never> {
        showPhotoLibraryUnavailableSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var showTermsAndConditionsSignal: AnyPublisher<Void, Never> {
        showTermsAndConditionsSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var phrasesDriver: AnyPublisher<[String], Never> {
        $phrases.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var errorSignal: AnyPublisher<String, Never> {
        errorSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    // MARK: - Actions

    func renewPhrases() {
        analyticsManager.log(event: .backingUpRenewing)
        createPhrases()
    }

    func copyToClipboard() {
        analyticsManager.log(event: .backingUpCopying)
        clipboardManager.copyToClipboard(phrases.joined(separator: " "))
        notificationsService.showInAppNotification(.message(L10n.seedPhraseCopiedToClipboard))
    }

    func saveKeysImage(_ image: UIImage) {
        imageSaver.save(image: image) { [weak self] result in
            switch result {
            case .success:
                self?.notificationsService.showInAppNotification(.done(L10n.savedToPhotoLibrary))
            case let .failure(error):
                switch error {
                case .noAccess:
                    self?.showPhotoLibraryUnavailableSubject.send()
                case .restrictedRightNow:
                    break
                case let .unknown(error):
                    self?.notificationsService.showInAppNotification(.error(error))
                }
            }
        }
    }

    @objc func saveToICloud() {
        deviceOwnerAuthenticationHandler.requiredOwner {
            self._saveToIcloud()
        } onFailure: { error in
            guard let error = error else { return }
            self.errorSubject.send(error)
        }
    }

    private func _saveToIcloud() {
        let result = iCloudStorage.saveToICloud(
            account: .init(
                name: nil,
                phrase: phrases.joined(separator: " "),
                derivablePath: .default
            )
        )

        if result {
            analyticsManager.log(event: .backingUpIcloud)
            notificationsService.showInAppNotification(.done(L10n.savedToICloud))
            createWalletViewModel.handlePhrases(phrases)
        } else {
            analyticsManager.log(event: .backingUpError)
            errorSubject.send(L10n.SecurityKeyCanTBeSavedIntoIcloud.pleaseTryAgain)
        }
    }

    func termsAndConditions() {
        showTermsAndConditionsSubject.send()
    }

    func verifyPhrase() {
        analyticsManager.log(event: .backingUpManually)
        createWalletViewModel.verifyPhrase(phrases)
    }

    @objc func back() {
        createWalletViewModel.back()
    }
}
