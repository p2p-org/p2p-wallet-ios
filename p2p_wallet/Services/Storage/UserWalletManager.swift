// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import KeyAppBusiness
import Onboarding
import Resolver
import SolanaSwift

/// Centralized class for managing user accounts
class UserWalletManager: ObservableObject {
    @Injected private var storage: KeychainStorage
    @Injected private var walletSettings: WalletSettings
    @Injected private var notificationsService: NotificationService
    @Injected private var solanaTracker: SolanaTracker

    /// Current selected wallet
    @Published private(set) var wallet: UserWallet? {
        didSet {
            notificationsService.registerForRemoteNotifications()
        }
    }

    /// Check if user logged in using web3 auth
    var isUserLoggedInUsingWeb3: Bool {
        wallet?.ethAddress != nil
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
            deviceShare: nil,
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

        // Save device share
        if let deviceShare = deviceShare, ethAddress != nil {
            try storage.save(deviceShare: deviceShare)
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
        Task.detached { try await Resolver.resolve(SendHistoryLocalProvider.self).save(nil) }

        // Storage
        storage.clearAccount()
        Defaults.walletName = [:]
        Defaults.didSetEnableBiometry = false
        Defaults.didSetEnableNotifications = false
        Defaults.didBackupOffline = false
        Defaults.forceCloseNameServiceBanner = false
        Defaults.shouldShowConfirmAlertOnSend = true
        Defaults.shouldShowConfirmAlertOnSwap = true
        Defaults.moonpayInfoShouldHide = false
        Defaults.isSellInfoPresented = false
        Defaults.isTokenInputTypeChosen = false
        Defaults.fromTokenAddress = nil
        Defaults.toTokenAddress = nil

        walletSettings.reset()

        // Reset wallet
        wallet = nil
        solanaTracker.stopTracking()
    }
}
