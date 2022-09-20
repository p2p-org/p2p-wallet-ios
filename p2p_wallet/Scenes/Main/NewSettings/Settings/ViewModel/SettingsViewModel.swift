//
//  SettingsViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 31.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import LocalAuthentication
import Resolver
import RxCombine
import SolanaSwift

final class SettingsViewModel: ObservableObject {
    @Injected private var nameStorage: NameStorageType
    @Injected private var solanaStorage: SolanaAccountStorage
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var logoutResponder: LogoutResponder
    @Injected private var authenticationHandler: AuthenticationHandlerType

    @Published var zeroBalancesIsHidden = Defaults.hideZeroBalances {
        didSet {
            toggleZeroBalancesVisibility()
        }
    }

    @Published var biometryIsAvailable = false
    @Published var biometryIsEnabled = Defaults.isBiometryEnabled {
        didSet {
            toggleBiometryEnabling()
        }
    }

    @Published var biometryType: BiometryType = .none
    var error: Error? {
        didSet {
            errorAlertPresented.toggle()
        }
    }

    @Published var errorAlertPresented = false

    private let openActionSubject = PassthroughSubject<OpenAction, Never>()
    var openAction: AnyPublisher<OpenAction, Never> { openActionSubject.eraseToAnyPublisher() }

    private var storageName: String? { nameStorage.getName() }
    @Published var name: String = ""

    private var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }
    var appInfo: String {
        "\(appVersion)\(Environment.current != .release ? ("(" + Bundle.main.buildVersionNumber + ")" + " " + Environment.current.description) : "")"
    }

    init() {
        setUpAuthType()
        updateNameIfNeeded()
    }

    private func setUpAuthType() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            biometryIsAvailable = true
        }

        switch context.biometryType {
        case .faceID:
            biometryType = .face
        case .touchID:
            biometryType = .touch
        default:
            biometryType = .none
        }
    }

    private func toggleBiometryEnabling() {
        authenticationHandler.pauseAuthentication(true)
        let context = LAContext()

        Task {
            do {
                try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: L10n.identifyYourself
                )
                Defaults.isBiometryEnabled.toggle()
                analyticsManager.log(event: AmplitudeEvent.settingsSecuritySelected(faceId: Defaults.isBiometryEnabled))
            } catch {
                if let authError = error as? LAError, authError.errorCode == kLAErrorUserCancel {
                    return
                } else {
                    self.error = error
                }
                biometryIsEnabled = Defaults.isBiometryEnabled
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.authenticationHandler.pauseAuthentication(false)
        }
    }

    func showView(_ type: OpenAction) {
        switch type {
        case .username, .reserveUsername:
            if storageName != nil {
                openActionSubject.send(.username)
            } else {
                guard let userAddress = solanaStorage.account?.publicKey.base58EncodedString else { return }
                openActionSubject.send(.reserveUsername(userAddress: userAddress))
            }
        default:
            openActionSubject.send(type)
        }
    }

    func sendSignOutAnalytics() {
        analyticsManager.log(event: AmplitudeEvent.signOut(lastScreen: "Settings"))
    }

    func signOut() {
        analyticsManager.log(event: AmplitudeEvent.signedOut)
        logoutResponder.logout()
    }

    private func toggleZeroBalancesVisibility() {
        Defaults.hideZeroBalances.toggle()
        analyticsManager.log(event: AmplitudeEvent.settingsHideBalancesClick(hide: Defaults.hideZeroBalances))
    }

    func updateNameIfNeeded() {
        name = storageName != nil ? storageName!.withNameServiceDomain() : L10n.notReserved
    }
}

// MARK: - Open Action

extension SettingsViewModel {
    enum OpenAction {
        case username
        case reserveUsername(userAddress: String)
        case recoveryKit
        case yourPin
        case network
    }
}

// MARK: - Environment Description

private extension Environment {
    var description: String {
        switch self {
        case .debug:
            return "Debug"
        case .test:
            return "Test"
        case .release:
            return "Release"
        }
    }
}
