// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import JSBridge
import SolanaSwift
import WebKit

public class TKeyMockupFacade: TKeyFacade {
    public init() {}

    public func initialize() async throws {}

    public func obtainTorusKey(tokenID: TokenID) async throws -> TorusKey {
        .init(tokenID: tokenID, value: "")
    }

    public func signUp(torusKey _: TorusKey, privateInput: String) async throws -> SignUpResult {
        .init(
            privateSOL: privateInput,
            reconstructedETH: "someEthPublicKey",
            deviceShare: "someDeviceShare",
            customShare: "someCustomShare",
            metaData: "someMetadata"
        )
    }

    public func signIn(torusKey _: TorusKey, deviceShare _: String) async throws -> SignInResult {
        .init(privateSOL: Mnemonic().phrase.joined(separator: " "), reconstructedETH: "someEthPublicKey")
    }

    public func signIn(
        torusKey _: TorusKey,
        customShare _: String,
        encryptedMnemonic _: String
    ) async throws -> SignInResult {
        .init(privateSOL: Mnemonic().phrase.joined(separator: " "), reconstructedETH: "someEthPublicKey")
    }

    public func signIn(
        deviceShare _: String,
        customShare _: String,
        encryptedMnemonic _: String
    ) async throws -> SignInResult {
        .init(privateSOL: Mnemonic().phrase.joined(separator: " "), reconstructedETH: "someEthPublicKey")
    }
}
