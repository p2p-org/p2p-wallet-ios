import AnalyticsManager
import Combine
import Foundation
import LocalAuthentication
import Onboarding
import Resolver
import SolanaSwift
import UIKit

final class SettingsViewModel: BaseViewModel, ObservableObject {
    @Injected private var nameStorage: NameStorageType
    @Injected private var solanaStorage: SolanaAccountStorage
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var userWalletManager: UserWalletManager
    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var metadataService: WalletMetadataService
    @Injected private var createNameService: CreateNameService
    @Injected private var deviceShareMigrationService: DeviceShareMigrationService

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

    private var isBiometryCheckGoing: Bool = false

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
    @Published var isNameEnabled: Bool = true

    @Published var deviceShareMigrationAlert: Bool = false

    @Published var isReferralProgramEnabled: Bool
    let openReferralProgramDetails = PassthroughSubject<Void, Never>()
    let shareReferralLink = PassthroughSubject<Void, Never>()

    var appInfo: String {
        AppInfo.appVersionDetail
    }

    override init() {
        isReferralProgramEnabled = available(.referralProgramEnabled)
        super.init()
        setUpAuthType()
        updateNameIfNeeded()
        bind()

        openActionSubject.compactMap {
            switch $0 {
            case .yourPin:
                return KeyAppAnalyticsEvent.settingsPinClick
            case .recoveryKit:
                return KeyAppAnalyticsEvent.settingsRecoveryClick
            default:
                return nil
            }
        }.sink { [weak self] event in
            self?.analyticsManager.log(event: event)
        }.store(in: &subscriptions)
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
        analyticsManager.log(event: .settingsFaceidClick)
        guard !isBiometryCheckGoing else { return }
        authenticationHandler.pauseAuthentication(true)
        let context = LAContext()
        context.localizedFallbackTitle = ""
        isBiometryCheckGoing = true
        Task {
            do {
                try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: L10n.identifyYourself
                )
                Defaults.isBiometryEnabled.toggle()
                analyticsManager.log(event: .settingsSecuritySelected(faceId: Defaults.isBiometryEnabled))
                isBiometryCheckGoing = false
            } catch {
                if let authError = error as? LAError, authError.errorCode != kLAErrorUserCancel {
                    self.error = error
                }
                biometryIsEnabled = Defaults.isBiometryEnabled
                isBiometryCheckGoing = false
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
        analyticsManager.log(event: .settingsLogOut)
    }

    func signOut() {
        analyticsManager.log(event: .signedOut)
        Task { try await userWalletManager.remove() }
    }

    private func toggleZeroBalancesVisibility() {
        Defaults.hideZeroBalances.toggle()
        analyticsManager.log(event: .settingsHideBalancesClick(hide: Defaults.hideZeroBalances))
    }

    func updateNameIfNeeded() {
        name = storageName != nil ? storageName! : L10n.notReserved
        if storageName == nil {
            isNameEnabled = available(.onboardingUsernameEnabled) && metadataService.metadata.value != nil
        } else {
            isNameEnabled = true
        }
    }

    private func bind() {
        deviceShareMigrationService
            .isMigrationAvailablePublisher
            .sink { [weak self] migrationIsAvailable in
                self?.deviceShareMigrationAlert = migrationIsAvailable
            }
            .store(in: &subscriptions)

        createNameService.createNameResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSuccess in
                guard let self = self, isSuccess else { return }
                self.updateNameIfNeeded()
            }
            .store(in: &subscriptions)

        openReferralProgramDetails
            .map { OpenAction.referral }
            .sink { [weak self] navigation in
                self?.openActionSubject.send(navigation)
            }
            .store(in: &subscriptions)

        shareReferralLink
            .map { OpenAction.shareReferral(URL(string: "https://www.google.com/")!) }
            .sink { [weak self] navigation in
                self?.openActionSubject.send(navigation)
            }
            .store(in: &subscriptions)
    }

    func openTwitter() {
        if let url = URL(string: "https://twitter.com/KeyApp_") {
            UIApplication.shared.open(url)
        }
    }

    func openDiscord() {
        if let url = URL(string: "https://discord.gg/SpW3GmEYgU") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Open Action

extension SettingsViewModel {
    enum OpenAction {
        case username
        case reserveUsername(userAddress: String)
        case recoveryKit
        case yourPin
        case referral
        case shareReferral(URL)
    }
}
