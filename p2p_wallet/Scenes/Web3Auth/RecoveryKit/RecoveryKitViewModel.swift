// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AnalyticsManager
import Combine
import Foundation
import Onboarding
import Resolver

final class RecoveryKitViewModel: ObservableObject {
    private let analyticsManager: AnalyticsManager
    private let userWalletManager: UserWalletManager
    private let walletMetadataService: WalletMetadataService

    @Published var model: Model?

    let actions = PassthroughSubject<Action, Never>()

    private var subscriptions = [AnyCancellable]()

    init(
        userWalletManager: UserWalletManager = Resolver.resolve(),
        walletMetadataService: WalletMetadataServiceImpl = Resolver.resolve(),
        deviceShareMigrationService: DeviceShareMigrationService = Resolver.resolve(),
        analyticsManager: AnalyticsManager = Resolver.resolve()
    ) {
        self.walletMetadataService = walletMetadataService
        self.analyticsManager = analyticsManager
        self.userWalletManager = userWalletManager

        Task.detached { await walletMetadataService.synchronize() }

        Publishers
            .CombineLatest(
                walletMetadataService.metadataPublisher,
                deviceShareMigrationService.isMigrationAvailablePublisher
            )
            .receive(on: RunLoop.main)
            .sink { [weak self, weak userWalletManager] metedataState, deviceShareMigration in
                if let metadata = metedataState.value {
                    self?.model = .init(
                        deviceName: metadata.deviceName,
                        isAnotherDevice: deviceShareMigration,
                        email: metadata.email,
                        authProvider: metadata.authProvider,
                        phoneNumber: metadata.phoneNumber
                    )
                } else if userWalletManager?.wallet?.ethAddress != nil {
                    self?.model = .init(
                        deviceName: L10n.notAvailableForNow,
                        isAnotherDevice: false,
                        email: L10n.notAvailableForNow,
                        authProvider: "apple",
                        phoneNumber: L10n.notAvailableForNow
                    )
                }
            }.store(in: &subscriptions)
    }

    func openSeedPhrase() {
        actions.send(.seedPhrase)
    }

    func deleteAccount() {
        analyticsManager.log(event: .startDeleteAccount)
        actions.send(.deleteAccount)
    }

    func openDevices() {
        actions.send(.devices)
    }

    func openHelp() {
        actions.send(.help)
    }
}

extension RecoveryKitViewModel {
    enum Action {
        case seedPhrase
        case deleteAccount
        case help
        case devices
    }

    struct Model {
        let deviceName: String
        let isAnotherDevice: Bool

        let email: String
        let authProvider: String
        let phoneNumber: String
    }
}
