// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift

public struct OnboardingWallet: Codable, Equatable {
    public let seedPhrase: String
    public let derivablePath: DerivablePath

    init(seedPhrase: String, derivablePath: DerivablePath? = nil) {
        self.seedPhrase = seedPhrase
        self.derivablePath = derivablePath ?? .default
    }
}
