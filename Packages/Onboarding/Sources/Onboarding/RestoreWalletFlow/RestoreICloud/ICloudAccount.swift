// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

public struct ICloudAccount: Codable, Hashable {
    public let name: String?
    internal let phrase: String
    public let derivablePath: DerivablePath
    public let publicKey: String

    public init(name: String?, phrase: String, derivablePath: DerivablePath, publicKey: String) {
        self.name = name
        self.phrase = phrase
        self.derivablePath = derivablePath
        self.publicKey = publicKey
    }

    init(name: String?, phrase: String, derivablePath: DerivablePath) async throws {
        self.name = name
        self.phrase = phrase
        self.derivablePath = derivablePath

        let account = try await Account(
            phrase: phrase.components(separatedBy: " "),
            network: .mainnetBeta,
            derivablePath: derivablePath
        )
        publicKey = account.publicKey.base58EncodedString
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(phrase)
        hasher.combine(derivablePath)
        hasher.combine(publicKey)
    }

    public static func == (lhs: ICloudAccount, rhs: ICloudAccount) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.phrase != rhs.phrase { return false }
        if lhs.derivablePath != rhs.derivablePath { return false }
        if lhs.publicKey != rhs.publicKey { return false }
        return true
    }
}

public protocol ICloudAccountProvider {
    func getAll() async throws -> [(name: String?, phrase: String, derivablePath: DerivablePath)]
}
