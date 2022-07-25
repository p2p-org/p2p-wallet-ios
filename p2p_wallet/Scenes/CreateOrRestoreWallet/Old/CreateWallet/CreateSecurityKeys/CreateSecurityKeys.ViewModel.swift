//
//  CreateSecurityKeys.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import AnalyticsManager
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift
import UIKit

protocol CreateSecurityKeysViewModelType: AnyObject {
    var showTermsAndConditionsSignal: Signal<Void> { get }
    var showPhotoLibraryUnavailableSignal: Signal<Void> { get }
    var phrasesDriver: Driver<[String]> { get }
    var errorSignal: Signal<String> { get }

    func copyToClipboard()
    func renewPhrases()

    func saveToICloud()
    func back()
    func verifyPhrase()
    func termsAndConditions()
    func saveKeysImage(_: UIImage)
}

extension CreateSecurityKeys {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var iCloudStorage: ICloudStorageType
        @Injected private var analyticsManager: AnalyticsManager
        private let createWalletViewModel: CreateWalletViewModelType
        @Injected private var deviceOwnerAuthenticationHandler: DeviceOwnerAuthenticationHandler
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationsService: NotificationService
        @Injected var imageSaver: ImageSaverType

        // MARK: - Subjects

        private let showTermsAndConditionsSubject = PublishRelay<Void>()
        private let showPhotoLibraryUnavailableSubject = PublishRelay<Void>()
        private let phrasesSubject = BehaviorRelay<[String]>(value: [])
        private let errorSubject = PublishRelay<String>()

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
            phrasesSubject.accept(mnemonic.phrase)
        }
    }
}

extension CreateSecurityKeys.ViewModel: CreateSecurityKeysViewModelType {
    var showPhotoLibraryUnavailableSignal: Signal<Void> {
        showPhotoLibraryUnavailableSubject.asSignal()
    }

    var showTermsAndConditionsSignal: Signal<Void> {
        showTermsAndConditionsSubject.asSignal()
    }

    var phrasesDriver: Driver<[String]> {
        phrasesSubject.asDriver()
    }

    var errorSignal: Signal<String> {
        errorSubject.asSignal()
    }

    // MARK: - Actions

    func renewPhrases() {
        analyticsManager.log(event: .backingUpRenewing)
        createPhrases()
    }

    func copyToClipboard() {
        analyticsManager.log(event: .backingUpCopying)
        clipboardManager.copyToClipboard(phrasesSubject.value.joined(separator: " "))
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
                    self?.showPhotoLibraryUnavailableSubject.accept(())
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
            self.errorSubject.accept(error)
        }
    }

    private func _saveToIcloud() {
        let result = iCloudStorage.saveToICloud(
            account: .init(
                name: nil,
                phrase: phrasesSubject.value.joined(separator: " "),
                derivablePath: .default
            )
        )

        if result {
            analyticsManager.log(event: .backingUpIcloud)
            notificationsService.showInAppNotification(.done(L10n.savedToICloud))
            createWalletViewModel.handlePhrases(phrasesSubject.value)
        } else {
            analyticsManager.log(event: .backingUpError)
            errorSubject.accept(L10n.SecurityKeyCanTBeSavedIntoIcloud.pleaseTryAgain)
        }
    }

    func termsAndConditions() {
        showTermsAndConditionsSubject.accept(())
    }

    func verifyPhrase() {
        analyticsManager.log(event: .backingUpManually)
        createWalletViewModel.verifyPhrase(phrasesSubject.value)
    }

    @objc func back() {
        createWalletViewModel.back()
    }
}
