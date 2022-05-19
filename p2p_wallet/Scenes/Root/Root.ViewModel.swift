//
//  Root.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import LocalAuthentication
import Resolver
import RxCocoa
import RxSwift

protocol RootViewModelType {
    var navigationSceneDriver: Driver<Root.NavigatableScene?> { get }
    var isLoadingDriver: Driver<Bool> { get }
    var resetSignal: Signal<Void> { get }

    func reload()
    func finishSetup()
}

extension Root {
    class ViewModel {
        // MARK: - Dependencies

        private var appEventHandler: AppEventHandlerType = Resolver.resolve()
        private let storage: AccountStorageType & PincodeStorageType & NameStorageType = Resolver.resolve()
        private let analyticsManager: AnalyticsManagerType = Resolver.resolve()
        private let notificationsService: NotificationService = Resolver.resolve()

        // MARK: - Properties

        private let disposeBag = DisposeBag()
        private var isRestoration = false
        private var showAuthenticationOnMainOnAppear = true

        // MARK: - Initializer

        init() {
            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        private let resetSubject = PublishRelay<Void>()

        // MARK: - Actions

        private func bind() {
            appEventHandler.delegate = self
            appEventHandler.isLoadingDriver
                .drive(isLoadingSubject)
                .disposed(by: disposeBag)
        }

        func reload() {
            // signal VC to prepare for reseting
            resetSubject.accept(())

            // reload session
            ResolverScope.session.reset()

            // mark as loading
            isLoadingSubject.accept(true)

            // try to retrieve account from seed
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                let account = self?.storage.account
                DispatchQueue.main.async { [weak self] in
                    if account == nil {
                        self?.showAuthenticationOnMainOnAppear = false
                        self?.navigationSubject.accept(.createOrRestoreWallet)
                    } else if self?.storage.pinCode == nil ||
                        !Defaults.didSetEnableBiometry ||
                        !Defaults.didSetEnableNotifications
                    {
                        self?.showAuthenticationOnMainOnAppear = false
                        self?.navigationSubject.accept(.onboarding)
                    } else {
                        self?.navigationSubject
                            .accept(.main(showAuthenticationWhenAppears: self?
                                    .showAuthenticationOnMainOnAppear ?? false))
                    }
                }
            }
        }

        @objc func finishSetup() {
            analyticsManager.log(event: .setupFinishClick)
            reload()
        }
    }
}

extension Root.ViewModel: RootViewModelType {
    var navigationSceneDriver: Driver<Root.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }

    var resetSignal: Signal<Void> {
        resetSubject.asSignal()
    }
}

extension Root.ViewModel: AppEventHandlerDelegate {
    func createWalletDidComplete() {
        isRestoration = false
        navigationSubject.accept(.onboarding)
        analyticsManager.log(event: .setupOpen(fromPage: "create_wallet"))
    }

    func restoreWalletDidComplete() {
        isRestoration = true
        navigationSubject.accept(.onboarding)
        analyticsManager.log(event: .setupOpen(fromPage: "recovery"))
    }

    func onboardingDidFinish(resolvedName: String?) {
        let event: AnalyticsEvent = isRestoration ? .setupWelcomeBackOpen : .setupFinishOpen
        analyticsManager.log(event: event)
        navigationSubject.accept(.onboardingDone(isRestoration: isRestoration, name: resolvedName))
    }

    func userDidChangeAPIEndpoint(to _: SolanaSDK.APIEndPoint) {
        showAuthenticationOnMainOnAppear = false
        reload()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.notificationsService.showInAppNotification(.done(L10n.networkChanged))
        }
    }

    func userDidChangeLanguage(to language: LocalizedLanguage) {
        showAuthenticationOnMainOnAppear = false
        reload()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let languageChangedText = language.originalName.map(L10n.changedLanguageTo) ?? L10n.interfaceLanguageChanged
            self?.notificationsService.showInAppNotification(.done(languageChangedText))
        }
    }

    func userDidLogout() {
        reload()
    }
}
