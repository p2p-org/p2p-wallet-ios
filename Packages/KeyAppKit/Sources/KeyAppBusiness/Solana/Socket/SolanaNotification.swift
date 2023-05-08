// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

struct SolanaNotification<T: Codable>: Codable {
    let result: Result
    let subscription: Int

    struct Result: Codable {
        let context: Context
        let value: T

        struct Context: Codable {
            let slot: UInt64
        }
    }
}

struct SolanaProgramChange: Codable {
    let pubkey: String?
    let account: Account

    struct Account: Codable {
        /// [Data, Encode]
        let data: [String]

        let executable: Bool

        let lamports: UInt64

        let owner: String

        let rentEpoch: UInt64
    }
}

struct SolanaAccountChange: Codable {
    /// [Data, Encode]
    let data: [String]

    let executable: Bool

    let lamports: UInt64

    let owner: String

    let rentEpoch: UInt64
}
