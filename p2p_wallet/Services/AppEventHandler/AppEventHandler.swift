//
//  AppEventHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/01/2022.
//

import Foundation
import LocalAuthentication
import RenVMSwift
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
    private var resolvedName: String?

    init() {
        disableDevnetTestnetIfDebug()
    }

    private func disableDevnetTestnetIfDebug() {
        #if !DEBUG
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
        #endif
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

// MARK: - LogoutResponder

extension AppEventHandler: LogoutResponder {
    func logout() {
        Resolver.resolve(Socket.self).disconnect()
        Resolver.resolve(PricesServiceType.self).stopObserving()

        ResolverScope.session.reset()
        notificationsService.unregisterForRemoteNotifications()

        Task {
            await notificationsService.deleteDeviceToken()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.storage.clearAccount()
            Defaults.walletName = [:]
            Defaults.didSetEnableBiometry = false
            Defaults.didSetEnableNotifications = false
            Defaults.didBackupOffline = false
            UserDefaults.standard.removeObject(forKey: LockAndMint.keyForSession)
            UserDefaults.standard.removeObject(forKey: LockAndMint.keyForGatewayAddress)
            UserDefaults.standard.removeObject(forKey: LockAndMint.keyForProcessingTransactions)
            UserDefaults.standard.removeObject(forKey: BurnAndRelease.keyForSubmitedBurnTransaction)
            Defaults.forceCloseNameServiceBanner = false
            Defaults.shouldShowConfirmAlertOnSend = true
            Defaults.shouldShowConfirmAlertOnSwap = true
            self.delegate?.userDidLogout()
        }
    }
}

// MARK: - CreateOrRestoreWalletHandler

extension AppEventHandler: CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete(phrases: [String]?, derivablePath: DerivablePath?, name: String?) {
        delegate?.createWalletDidComplete()
        saveAccountToStorage(phrases: phrases, derivablePath: derivablePath, name: name)
        resolvedName = name
    }

    func restoringWalletDidComplete(phrases: [String]?, derivablePath: DerivablePath?, name: String?) {
        delegate?.restoreWalletDidComplete()
        saveAccountToStorage(phrases: phrases, derivablePath: derivablePath, name: name)
        resolvedName = name
    }

    func creatingOrRestoringWalletDidCancel() {
        logout()
        delegate?.userDidLogout()
    }

    private func saveAccountToStorage(phrases: [String]?, derivablePath: DerivablePath?, name: String?) {
        guard let phrases = phrases, let derivablePath = derivablePath else {
            creatingOrRestoringWalletDidCancel()
            return
        }

        delegate?.didStartLoading()

        Task {
            do {
                try storage.save(phrases: phrases)
                try storage.save(derivableType: derivablePath.type)
                try storage.save(walletIndex: derivablePath.walletIndex)

                try await storage.reloadSolanaAccount()

                if let name = name {
                    storage.save(name: name)
                }

                await MainActor.run {
                    delegate?.didStopLoading()
                }
            } catch {
                await MainActor.run {
                    delegate?.didStopLoading()
                    notificationsService.showInAppNotification(.error(error))
                    creatingOrRestoringWalletDidCancel()
                }
            }
        }
    }
}

// MARK: - OnboardingHandler

extension AppEventHandler: OnboardingHandler {
    func onboardingDidCancel() {
        logout()
    }

    func onboardingDidComplete() {
        delegate?.onboardingDidFinish(resolvedName: resolvedName)
    }
}

// MARK: - DeviceOwnerAuthenticationHandler

extension AppEventHandler: DeviceOwnerAuthenticationHandler {
    func requiredOwner(onSuccess: (() -> Void)?, onFailure: ((String?) -> Void)?) {
        let myContext = LAContext()

        var error: NSError?
        guard myContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                onFailure?(errorToString(error))
            }
            return
        }

        myContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: L10n.confirmItSYou) { success, error in
            guard success else {
                DispatchQueue.main.async {
                    onFailure?(errorToString(error))
                }
                return
            }
            DispatchQueue.main.sync {
                onSuccess?()
            }
        }
    }
}

// MARK: - Helpers

private func errorToString(_ error: Error?) -> String? {
    var error = error?.localizedDescription ?? L10n.unknownError
    switch error {
    case "Passcode not set.":
        error = L10n.PasscodeNotSet.soWeCanTVerifyYouAsTheDeviceSOwner
    case "Canceled by user.":
        return nil
    default:
        break
    }
    return error
}
