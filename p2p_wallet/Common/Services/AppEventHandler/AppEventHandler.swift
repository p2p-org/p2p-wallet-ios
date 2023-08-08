import Foundation
import LocalAuthentication
import Resolver
import SolanaSwift
import UIKit

protocol AppEventHandlerType {
    var delegate: AppEventHandlerDelegate? { get set }
}

final class AppEventHandler: AppEventHandlerType {
    // MARK: - Properties

    weak var delegate: AppEventHandlerDelegate?

    init() {
        disableDevnetTestnetIfDebug()
    }

    private func disableDevnetTestnetIfDebug() {
        if Environment.current == Environment.release {
            switch Defaults.apiEndPoint.network {
            case .mainnetBeta:
                break
            case .devnet, .testnet:
                if let definedEndpoint = (APIEndPoint.definedEndpoints
                    .first { $0.network != .devnet && $0.network != .testnet })
                {
                    changeAPIEndpoint(to: definedEndpoint)
                }
            }
        }
    }
}

// MARK: - ChangeNetworkResponder

extension AppEventHandler: ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: APIEndPoint) {
        Defaults.apiEndPoint = endpoint
        ResolverScope.session.reset()
        delegate?.userDidChangeAPIEndpoint(to: endpoint)
    }
}

// MARK: - ChangeLanguageResponder

extension AppEventHandler: ChangeLanguageResponder {
    func languageDidChange(to: LocalizedLanguage) {
        delegate?.userDidChangeLanguage(to: to)
    }
}

// MARK: - ChangeThemeResponder

extension AppEventHandler: ChangeThemeResponder {
    func changeThemeTo(_ style: UIUserInterfaceStyle) {
        Defaults.appearance = style
        delegate?.userDidChangeTheme(to: style)
    }
}
