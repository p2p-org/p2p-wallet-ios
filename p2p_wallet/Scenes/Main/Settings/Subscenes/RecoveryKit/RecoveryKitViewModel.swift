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

class RecoveryKitViewModel: ObservableObject {
    private let analyticsManager: AnalyticsManager
    private let walletMetadataService: WalletMetadataService

    @Published var walletMetadata: WalletMetaData?

    private var subscriptions = [AnyCancellable]()

    struct Coordinator {
        var seedPhrase: (() -> Void)?
        var deleteAccount: (() -> Void)?
        var help: (() -> Void)?
    }

    var coordinator: Coordinator = .init()

    init(
        walletMetadataService: WalletMetadataService = Resolver.resolve(),
        analyticsManager: AnalyticsManager = Resolver.resolve()
    ) {
        self.walletMetadataService = walletMetadataService
        self.analyticsManager = analyticsManager
        walletMetadataService.$metadata
            .sink { [weak self] metadata in
                self?.walletMetadata = metadata
            }.store(in: &subscriptions)
    }

    func openSeedPhrase() {
        coordinator.seedPhrase?()
    }
    
    func deleteAccount() {
        analyticsManager.log(event: AmplitudeEvent.startDeleteAccount)
        coordinator.deleteAccount?()
    }

    func openHelp() {
        coordinator.help?()
    }
}
