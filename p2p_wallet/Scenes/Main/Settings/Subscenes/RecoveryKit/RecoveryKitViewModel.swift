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
    @Injected private var accountStorage: AccountStorageType

    @Published var tKeyData: RecoveryKitTKeyData?

    override init() {
        if
    }
}
