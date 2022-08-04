//
//  AppCoordinator+AppEventHandlerDelegate.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/05/2022.
//

import AnalyticsManager
import Foundation
import SolanaSwift

extension AppCoordinator: AppEventHandlerDelegate {
    func didStartLoading() {
        window?.showLoadingIndicatorView()
    }

    func didStopLoading() {
        window?.hideLoadingIndicatorView()
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

    func userDidChangeAPIEndpoint(to _: APIEndPoint) {
        showAuthenticationOnMainOnAppear = false
        Task {
            await reload()
            await MainActor.run {
                notificationsService.showInAppNotification(.done(L10n.networkChanged))
            }
        }
    }

    func userDidChangeLanguage(to language: LocalizedLanguage) {
        showAuthenticationOnMainOnAppear = false

        Task {
            await reload()
            await MainActor.run {
                let languageChangedText = language.originalName.map(L10n.changedLanguageTo) ?? L10n
                    .interfaceLanguageChanged
                notificationsService.showInAppNotification(.done(languageChangedText))
            }
        }
    }

    func userDidChangeTheme(to style: UIUserInterfaceStyle) {
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = style
        }
    }

    func userDidLogout() {
        Task {
            await reload()
        }
    }
}
