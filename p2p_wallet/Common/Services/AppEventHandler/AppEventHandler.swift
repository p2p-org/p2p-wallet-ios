//
//  AppEventHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/01/2022.
//

import Foundation
import LocalAuthentication
import Resolver
import SolanaSwift

protocol AppEventHandlerType {
    var delegate: AppEventHandlerDelegate? { get set }
}

final class AppEventHandler: AppEventHandlerType {
    // MARK: - Dependencies

    private let storage: AccountStorageType & PincodeStorageType & NameStorageType = Resolver.resolve()
    private let notificationsService: NotificationService = Resolver.resolve()

    // MARK: - Properties

    weak var delegate: AppEventHandlerDelegate?

    @available(*, deprecated, message: "Will be removed")
    private var resolvedName: String?

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
        UIApplication.languageChanged()
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
