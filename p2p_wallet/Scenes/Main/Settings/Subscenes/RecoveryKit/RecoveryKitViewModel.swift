// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AnalyticsManager
import Combine
import Foundation
import Onboarding
import Resolver

struct RecoveryKitTKeyData {
    let device: String
    let phone: String

    let social: String
    let socialProvider: String
}

final class RecoveryKitViewModel: ObservableObject {
    private let analyticsManager: AnalyticsManager
    private let userWalletManager: UserWalletManager
    private let walletMetadataService: WalletMetadataService

    @Published var walletMetadata: WalletMetaData?

    private var subscriptions = [AnyCancellable]()

    struct Coordinator {
        var seedPhrase: (() -> Void)?
        var deleteAccount: (() -> Void)?
        var help: (() -> Void)?
    }

    var coordinator = Coordinator()

    init(
        userWalletManager: UserWalletManager = Resolver.resolve(),
        walletMetadataService: WalletMetadataService = Resolver.resolve(),
        analyticsManager: AnalyticsManager = Resolver.resolve()
    ) {
        self.walletMetadataService = walletMetadataService
        self.analyticsManager = analyticsManager
        self.userWalletManager = userWalletManager
        
        walletMetadataService.$metadata
            .sink { [weak self, weak userWalletManager] metadata in
                if let metadata {
                    self?.walletMetadata = metadata
                } else if userWalletManager?.wallet?.ethAddress != nil {
                    self?.walletMetadata = .init(
                        deviceName: L10n.notAvailableForNow,
                        email: L10n.notAvailableForNow,
                        authProvider: "apple",
                        phoneNumber: L10n.notAvailableForNow
                    )
                }
            }.store(in: &subscriptions)
    }

    func openSeedPhrase() {
        coordinator.seedPhrase?()
    }

    func deleteAccount() {
        analyticsManager.log(event: .startDeleteAccount)
        coordinator.deleteAccount?()
    }

    func openHelp() {
        coordinator.help?()
    }
}
