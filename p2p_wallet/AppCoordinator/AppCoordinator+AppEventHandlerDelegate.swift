//
//  AppCoordinator+AppEventHandlerDelegate.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/05/2022.
//

import Foundation

extension AppCoordinator: AppEventHandlerDelegate {
    func didStartLoading() {
        window.showLoadingIndicatorView()
    }

    func didStopLoading() {
        window.hideLoadingIndicatorView()
    }

    func createWalletDidComplete() {
        isRestoration = false
        navigateToOnboarding()
        analyticsManager.log(event: .setupOpen(fromPage: "create_wallet"))
    }

    func restoreWalletDidComplete() {
        isRestoration = true
        navigateToOnboarding()
        analyticsManager.log(event: .setupOpen(fromPage: "recovery"))
    }

    func onboardingDidFinish(resolvedName: String?) {
        self.resolvedName = resolvedName
        let event: AnalyticsEvent = isRestoration ? .setupWelcomeBackOpen : .setupFinishOpen
        analyticsManager.log(event: event)
        navigateToOnboardingDone()
    }

    func userDidChangeAPIEndpoint(to _: SolanaSDK.APIEndPoint) {
        showAuthenticationOnMainOnAppear = false
        Task {
            await reload()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.notificationsService.showInAppNotification(.done(L10n.networkChanged))
        }
    }

    func userDidChangeLanguage(to language: LocalizedLanguage) {
        showAuthenticationOnMainOnAppear = false

        Task {
            await reload()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let languageChangedText = language.originalName.map(L10n.changedLanguageTo) ?? L10n.interfaceLanguageChanged
            self?.notificationsService.showInAppNotification(.done(languageChangedText))
        }
    }

    func userDidLogout() {
        Task {
            await reload()
        }
    }
}
