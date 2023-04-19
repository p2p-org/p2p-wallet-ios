// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import TweetNacl

internal func extractOnboardingSeedPhrase(phrase: String, path: String) throws -> Data {
    let mnemonic = try Mnemonic(phrase: phrase.components(separatedBy: " "))
    let secretKey = try Ed25519HDKey.derivePath(path, seed: mnemonic.seed.toHexString()).get().key
    let keyPair = try NaclSign.KeyPair.keyPair(fromSeed: secretKey)
    let result = keyPair.secretKey.prefix(32)
    return result
}
