// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Onboarding
import RenVMSwift
import Resolver
import SolanaSwift

/// Centralized class for managing user accounts
class UserWalletManager: ObservableObject {
    @Injected private var storage: KeychainStorage
    @Injected private var notificationsService: NotificationService
    @Injected private var solanaTracker: SolanaTracker

    /// Current selected wallet
    @Published private(set) var wallet: UserWallet?

    /// Check if user logged in using web3 auth
    var isUserLoggedInUsingWeb3: Bool {
        wallet?.ethAddress != nil
    }

    init() {}

    func refresh() async throws {
        try await storage.reloadSolanaAccount()

        guard let account = storage.account else { return }

        wallet = .init(
            seedPhrase: account.phrase,
            derivablePath: storage.derivablePath,
            name: storage.getName(),
            deviceShare: nil,
            ethAddress: storage.ethAddress,
            account: account
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

        // Save device share
        if let deviceShare = deviceShare, ethAddress != nil {
            try storage.save(deviceShare: deviceShare)
        }

        try await refresh()
    }

    /// Remove a current selected wallet
    func remove() async throws {
        ResolverScope.session.reset()

        // Notification service
        notificationsService.unregisterForRemoteNotifications()
        Task.detached { [notificationsService] in await notificationsService.deleteDeviceToken() }

        // Storage
        storage.clearAccount()
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

        // Reset wallet
        wallet = nil
        solanaTracker.stopTracking()
    }
}
