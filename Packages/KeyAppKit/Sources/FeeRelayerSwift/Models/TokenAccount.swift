// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A basic class that represents SPL Token.
public struct TokenAccount: Equatable, Codable {
    public init(address: PublicKey, mint: PublicKey) {
        self.address = address
        self.mint = mint
    }

    /// A address of spl token.
    public let address: PublicKey

    /// A mint address for spl token.
    public let mint: PublicKey
}
