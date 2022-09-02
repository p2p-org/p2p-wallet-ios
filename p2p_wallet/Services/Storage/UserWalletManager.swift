// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import RenVMSwift
import Resolver
import SolanaSwift

class UserWalletManager: ObservableObject {
    @Injected private var storage: KeychainStorage
    @Injected private var notificationsService: NotificationService

    @Published var wallet: UserWallet?

    init() {}

    func refresh() async throws {
        try await storage.reloadSolanaAccount()

        guard let account = storage.account else { return }
        wallet = .init(
            seedPhrase: account.phrase,
            derivablePath: storage.derivablePath,
            name: storage.getName(),
            deviceShare: storage.deviceShare,
            ethAddress: storage.ethAddress,
            account: account
        )
    }

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
        try storage.save(name: name ?? "")
        try storage.save(ethAddress: ethAddress ?? "")
        if let deviceShare = deviceShare {
            try storage.save(deviceShare: deviceShare)
        }

        try await refresh()
    }

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
    }
}
