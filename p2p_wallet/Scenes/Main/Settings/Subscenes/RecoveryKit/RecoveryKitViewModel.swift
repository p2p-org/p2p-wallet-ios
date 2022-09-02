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

    var seedPhrase: (() -> Void)?

    init() {
        if
            let ethAddress = userWalletManager.wallet?.ethAddress,
            let deviceShare = userWalletManager.wallet?.deviceShare
        {
            tKeyData = .init(
                device: deviceShare,
                phone: "Unavailable",
                social: ethAddress,
                socialProvider: "Unavailable"
            )
        }
    }

    func openSeedPhrase() {
        seedPhrase?()
    }
}
