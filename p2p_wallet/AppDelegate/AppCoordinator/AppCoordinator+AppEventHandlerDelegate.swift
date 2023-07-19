import AnalyticsManager
import Foundation
import Resolver
import SolanaSwift
import UIKit

extension AppCoordinator: AppEventHandlerDelegate {
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
        window?.overrideUserInterfaceStyle = style
    }

    func disablePincodeOnFirstAppear() {
        showAuthenticationOnMainOnAppear = false
    }

    func refresh() {
        ResolverScope.session.reset()
        reloadEvent.send()
    }
}
