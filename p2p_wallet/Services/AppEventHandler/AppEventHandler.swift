//
//  AppEventHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/01/2022.
//

import Foundation
import LocalAuthentication
import RxCocoa

protocol AppEventHandlerType {
    var isLoadingDriver: Driver<Bool> { get }
    var delegate: AppEventHandlerDelegate? { get set }
}

final class AppEventHandler {
    // MARK: - Dependencies

    private let storage: AccountStorageType & PincodeStorageType & NameStorageType = Resolver.resolve()
    private let notificationsService: NotificationsServiceType = Resolver.resolve()

    // MARK: - Properties

    private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
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
                if let definedEndpoint = (SolanaSDK.APIEndPoint.definedEndpoints
                    .first { $0.network != .devnet && $0.network != .testnet })
                {
                    changeAPIEndpoint(to: definedEndpoint)
                }
            }
        #endif
    }
}

extension AppEventHandler: AppEventHandlerType {
    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }
}

// MARK: - ChangeNetworkResponder

extension AppEventHandler: ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint) {
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

// MARK: - LogoutResponder

extension AppEventHandler: LogoutResponder {
    func logout() {
        storage.clearAccount()
        Defaults.walletName = [:]
        Defaults.didSetEnableBiometry = false
        Defaults.didSetEnableNotifications = false
        Defaults.didBackupOffline = false
        Defaults.renVMSession = nil
        Defaults.renVMProcessingTxs = []
        Defaults.forceCloseNameServiceBanner = false
        Defaults.shouldShowConfirmAlertOnSend = true
        Defaults.shouldShowConfirmAlertOnSwap = true
        delegate?.userDidLogout()
    }
}

// MARK: - CreateOrRestoreWalletHandler

extension AppEventHandler: CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?) {
        delegate?.createWalletDidComplete()
        saveAccountToStorage(phrases: phrases, derivablePath: derivablePath, name: name)
        resolvedName = name
    }

    func restoringWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?) {
        delegate?.restoreWalletDidComplete()
        saveAccountToStorage(phrases: phrases, derivablePath: derivablePath, name: name)
        resolvedName = name
    }

    func creatingOrRestoringWalletDidCancel() {
        logout()
        delegate?.userDidLogout()
    }

    private func saveAccountToStorage(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?) {
        guard let phrases = phrases, let derivablePath = derivablePath else {
            creatingOrRestoringWalletDidCancel()
            return
        }

        isLoadingSubject.accept(true)
        DispatchQueue.global().async { [weak self] in
            do {
                try self?.storage.save(phrases: phrases)
                try self?.storage.save(derivableType: derivablePath.type)
                try self?.storage.save(walletIndex: derivablePath.walletIndex)

                if let name = name {
                    self?.storage.save(name: name)
                }

                DispatchQueue.main.async { [weak self] in
                    self?.isLoadingSubject.accept(false)
                }
            } catch {
                self?.isLoadingSubject.accept(false)
                DispatchQueue.main.async { [weak self] in
                    self?.notificationsService.showInAppNotification(.error(error))
                    self?.creatingOrRestoringWalletDidCancel()
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
