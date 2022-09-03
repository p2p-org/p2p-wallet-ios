// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver

struct RecoveryKitTKeyData {
    let device: String
    let phone: String

    let social: String
    let socialProvider: String
}

class RecoveryKitViewModel: ObservableObject {
    @Injected private var userWalletManager: UserWalletManager

    @Published var tKeyData: RecoveryKitTKeyData?

    struct Coordinator {
        var seedPhrase: (() -> Void)?
        var help: (() -> Void)?
    }

    var coordinator: Coordinator = .init()

    init() {
        if let wallet = userWalletManager.wallet {
            if let ethAddress = wallet.ethAddress {
                tKeyData = .init(
                    device: wallet.deviceShare ?? "Unavailable",
                    phone: "Unavailable",
                    social: ethAddress,
                    socialProvider: "Unavailable"
                )
            }
        }
    }

    func openSeedPhrase() {
        coordinator.seedPhrase?()
    }

    func openHelp() {
        coordinator.help?()
    }
}
