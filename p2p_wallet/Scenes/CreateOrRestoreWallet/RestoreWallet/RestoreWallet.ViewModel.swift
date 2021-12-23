//
//  RestoreWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import Resolver

protocol RestoreWalletViewModelType: ReserveNameHandler {
    var navigatableSceneDriver: Driver<RestoreWallet.NavigatableScene?> { get }
    var isLoadingDriver: Driver<Bool> { get }
    var isRestorableUsingIcloud: Driver<Bool> { get }
    var errorSignal: Signal<String> { get }
    var finishedSignal: Signal<Void> { get }
    
    func handlePhrases(_ phrases: [String], derivablePath: SolanaSDK.DerivablePath?)
    func handleICloudAccount(_ account: Account)
    func restoreFromICloud()
    func restoreManually()
}

extension RestoreWallet {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var iCloudStorage: ICloudStorageType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var nameService: NameServiceType
        @Injected private var authenticationHandler: AuthenticationHandler
        @Injected private var notificationsService: NotificationsServiceType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var phrases: [String]?
        private var derivablePath: SolanaSDK.DerivablePath?
        private var name: String?
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<RestoreWallet.NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        private let isRestorableUsingIcloudSubject = BehaviorRelay<Bool>(value: true)
        private let errorSubject = PublishRelay<String>()
        private let finishedSubject = PublishRelay<Void>()
    }
}

extension RestoreWallet.ViewModel: RestoreWalletViewModelType {
    var isRestorableUsingIcloud: Driver<Bool> {
        isRestorableUsingIcloudSubject.asDriver()
    }
    
    var navigatableSceneDriver: Driver<RestoreWallet.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }
    
    var errorSignal: Signal<String> {
        errorSubject.asSignal()
    }
    
    var finishedSignal: Signal<Void> {
        finishedSubject.asSignal()
    }
    
    // MARK: - Actions
    func restoreFromICloud() {
        authenticationHandler.requiredOwner { [weak self] in
            self?._restoreFromIcloud()
        } onFailure: { [weak self] error in
            var error = error?.localizedDescription ?? L10n.error
            switch error {
            case "Passcode not set.":
                error = L10n.PasscodeNotSet.soWeCanTVerifyYouAsTheDeviceSOwner
            case "Canceled by user.":
                return
            default:
                break
            }
            self?.errorSubject.accept(error)
        }
    }
    
    private func _restoreFromIcloud() {
        guard let accounts = iCloudStorage.accountFromICloud(), accounts.count > 0
        else {
            isRestorableUsingIcloudSubject.accept(false)
            notificationsService.showInAppNotification(.message(L10n.thereIsNoP2PWalletSavedInYourICloud))
            return
        }
        analyticsManager.log(event: .recoveryRestoreIcloudClick)
        
        // if there is only 1 account saved in iCloud
        if accounts.count == 1 {
            handlePhrases(accounts[0].phrase.components(separatedBy: " "), derivablePath: accounts[0].derivablePath)
            return
        }
        
        // if there are more than 1 account saved in iCloud
        navigationSubject.accept(.restoreFromICloud)
    }
    
    func restoreManually() {
        analyticsManager.log(event: .recoveryRestoreManualyClick)
        navigationSubject.accept(.enterPhrases)
    }
    
    func handlePhrases(_ phrases: [String], derivablePath: SolanaSDK.DerivablePath?) {
        self.phrases = phrases
        if let derivablePath = derivablePath {
            derivablePathDidSelect(derivablePath, phrases: phrases)
        } else {
            navigationSubject.accept(.derivableAccounts(phrases: phrases))
        }
    }
    
    func handleICloudAccount(_ account: Account) {
        self.phrases = account.phrase.components(separatedBy: " ")
        self.derivablePath = account.derivablePath
        if let name = account.name {
            self.name = name
            finish()
        } else {
            // create account
            isLoadingSubject.accept(true)
            DispatchQueue(label: "Create account", qos: .userInteractive).async { [unowned self] in
                guard let phrases = self.phrases else { return }
                do {
                    let account = try SolanaSDK.Account(phrase: phrases, network: Defaults.apiEndPoint.network, derivablePath: derivablePath)
                    DispatchQueue.main.async { [weak self] in
                        // reserve name
                        self?.isLoadingSubject.accept(false)
                        self?.navigationSubject.accept(.reserveName(owner: account.publicKey.base58EncodedString))
                    }
                } catch {
                    self.errorSubject.accept(error.readableDescription)
                }
            }
        }
    }
}

extension RestoreWallet.ViewModel: AccountRestorationHandler {
    func derivablePathDidSelect(_ derivablePath: SolanaSDK.DerivablePath, phrases: [String]) {
        analyticsManager.log(event: .recoveryRestoreClick)
        self.derivablePath = derivablePath
        self.phrases = phrases
        
        // create account
        isLoadingSubject.accept(true)
        DispatchQueue(label: "Create account", qos: .userInteractive).async { [unowned self] in
            guard let phrases = self.phrases else { return }
            do {
                let account = try SolanaSDK.Account(phrase: phrases, network: Defaults.apiEndPoint.network, derivablePath: derivablePath)
                DispatchQueue.main.async { [weak self] in
                    self?.checkIfNameIsReservedAndReserveNameIfNeeded(owner: account.publicKey.base58EncodedString)
                }
            } catch {
                self.errorSubject.accept(error.readableDescription)
            }
        }
    }
    
    private func checkIfNameIsReservedAndReserveNameIfNeeded(owner: String) {
        nameService.getName(owner)
            .subscribe(onSuccess: { [weak self] name in
                self?.isLoadingSubject.accept(false)
                if let name = name {
                    self?.handleName(name)
                } else {
                    self?.navigationSubject.accept(.reserveName(owner: owner))
                }
            }, onFailure: { [weak self] _ in
                self?.isLoadingSubject.accept(false)
                self?.finish()
            })
            .disposed(by: disposeBag)
    }
}

extension RestoreWallet.ViewModel: ReserveNameHandler {
    func handleName(_ name: String?) {
        self.name = name
        finish()
    }
}

private extension RestoreWallet.ViewModel {
    func finish() {
        finishedSubject.accept(())
        handler.restoringWalletDidComplete(
            phrases: phrases,
            derivablePath: derivablePath,
            name: name
        )
    }
}
