import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Onboarding
import Resolver
import SolanaSwift

/// Centralized class for managing user accounts
class UserWalletManager: ObservableObject {
    @Injected private var storage: KeychainStorage
    @Injected private var walletSettings: WalletSettings
    @Injected private var notificationsService: NotificationService
    @Injected private var solanaTracker: SolanaTracker
    @Injected private var deviceShareManager: DeviceShareManager

    /// Current selected wallet
    @Published private(set) var wallet: UserWallet? {
        didSet {
            notificationsService.registerForRemoteNotifications()
        }
    }

    init() {}

    func refresh() async throws {
        try await storage.reloadSolanaAccount()

        // Legacy code
        guard let account = storage.account else { return }

        let moonpayAccount = try await KeyPair(
            phrase: account.phrase,
            network: .mainnetBeta,
            derivablePath: DerivablePath(type: storage.derivablePath.type, walletIndex: 101, accountIndex: 0)
        )

        let ethereumKeyPair = try EthereumKeyPair(phrase: account.phrase.joined(separator: " "))

        wallet = .init(
            seedPhrase: account.phrase,
            derivablePath: storage.derivablePath,
            name: storage.getName(),
            ethAddress: storage.ethAddress,
            account: account,
            moonpayExternalClientId: moonpayAccount.publicKey.base58EncodedString,
            ethereumKeypair: ethereumKeyPair
        )
    }

    /// Set a new wallet and use it as default
    func add(
        seedPhrase: [String],
        derivablePath: DerivablePath,
        name: String?,
        deviceShare: String?,
        ethAddress: String?
    ) async throws {
        try storage.save(phrases: seedPhrase)
        try storage.save(derivableType: derivablePath.type)
        try storage.save(walletIndex: derivablePath.walletIndex)
        storage.save(name: name ?? "")
        try storage.save(ethAddress: ethAddress ?? "")

        // Services
        try await Resolver.resolve(SendHistoryLocalProvider.self).save(nil)

        if let deviceShare = deviceShare, ethAddress != nil {
            deviceShareManager.save(deviceShare: deviceShare)
        }

        try await refresh()

        notificationsService.registerForRemoteNotifications()
    }

    /// Remove a current selected wallet
    func remove() async throws {
        ResolverScope.session.reset()

        // Notification service
        notificationsService.unregisterForRemoteNotifications()
        Task.detached { [notificationsService] in
            let ethAddress = available(.ethAddressEnabled) ? self.wallet?.ethAddress : nil
            try await notificationsService.deleteDeviceToken(ethAddress: ethAddress)
        }
        Task.detached {
            try await Resolver.resolve(SendHistoryLocalProvider.self).save(nil)
        }

        // Storage
        UserDefaults.standard.removeObject(forKey: "UserActionPersistentStorageWithUserDefault")

        storage.clearAccount()
        Defaults.walletName = [:]
        Defaults.didSetEnableBiometry = false
        Defaults.didSetEnableNotifications = false
        Defaults.didBackupOffline = false
        Defaults.forceCloseNameServiceBanner = false
        Defaults.shouldShowConfirmAlertOnSend = true
        Defaults.shouldShowConfirmAlertOnSwap = true
        Defaults.moonpayInfoShouldHide = false
        Defaults.ethBannerShouldHide = false
        Defaults.strigaOTPResendCounter = nil
        Defaults.strigaOTPConfirmErrorDate = nil
        Defaults.strigaOTPResendErrorDate = nil
        Defaults.isSellInfoPresented = false
        Defaults.isTokenInputTypeChosen = false
        Defaults.fromTokenAddress = nil
        Defaults.toTokenAddress = nil
        Defaults.region = nil
        Defaults.homeBannerVisibility = nil
        Defaults.strigaIBANInfoDoNotShow = false

        walletSettings.reset()

        // Reset wallet
        wallet = nil
        solanaTracker.stopTracking()
    }
}

extension UserWalletManager: CurrentUserWallet {
    var value: UserWallet? {
        wallet
    }

    var valuePublisher: AnyPublisher<UserWallet?, Never> {
        $wallet.eraseToAnyPublisher()
    }
}
