//
//  AppCoordinator+AppEventHandlerDelegate.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/05/2022.
//

import AnalyticsManager
import Foundation
import Resolver
import SolanaSwift

extension AppCoordinator: AppEventHandlerDelegate {
    func didStartLoading() {
        window?.showLoadingIndicatorView()
    }

    func didStopLoading() {
        window?.hideLoadingIndicatorView()
    }

    func userDidChangeAPIEndpoint(to _: APIEndPoint) {
        showAuthenticationOnMainOnAppear = false
        Task {
            ResolverScope.session.reset()
            reloadEvent.send()

            notificationsService.showInAppNotification(.done(L10n.networkChanged))
        }
    }

    func userDidChangeLanguage(to language: LocalizedLanguage) {
        showAuthenticationOnMainOnAppear = false

        Task {
            ResolverScope.session.reset()
            reloadEvent.send()

            let languageChangedText = language.originalName.map(L10n.changedLanguageTo) ?? L10n
                .interfaceLanguageChanged
            notificationsService.showInAppNotification(.done(languageChangedText))
        }
    }

    func userDidChangeTheme(to style: UIUserInterfaceStyle) {
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = style
        }
    }
}
