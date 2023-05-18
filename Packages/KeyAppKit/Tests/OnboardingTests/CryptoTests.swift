// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import CryptoKit
import CryptoSwift
import SolanaSwift
import XCTest
@testable import Onboarding
import TweetNacl

class CryptoTests: XCTestCase {
    func testExtractSymmetricKey() async throws {
        let secretData = "Hello world"
        let randomSeed = Mnemonic().phrase.joined(separator: " ")
        let encryptedMetadata = try Crypto.encryptMetadata(
            seedPhrase: randomSeed,
            data: Data(secretData.utf8)
        )

        let decryptedMetadata = try Crypto.decryptMetadata(seedPhrase: randomSeed, encryptedMetadata: encryptedMetadata)
        XCTAssertEqual(secretData, String(data: decryptedMetadata, encoding: .utf8)!)
    }

    // func testDecrypt() async throws {
    //     let m =
    //         "{\"nonce\":\"79bu2hlt/GKoZPzs\",\"metadata_ciphered\":\"1sK+bzqJt+dwPMySdcd5HPcW6zP2MBXx+gj2pnAoFO1eeD2U5ECD2ZvQEUpd1SxvEqYo2QK88jX1yp3x3VXHccHeGHNw370LOO75o9riLwKPm5x9wLdhCrpCqRtkauxRqTdEv1c/WoaUQkA1+LiKpgzcxvXd6++y66S9ErRhvtpLTe5jvGT76g64\",\"tag\":\"no_value\"}"
    //     let seed =
    //         "slice sauce assist glimpse jelly trouble parent horror bread isolate uncle gallery owner angry rose fabric stable phrase much joke cotton mesh ancient erase"
    //     let result = try WalletMetaData.decrypt(seedPhrase: seed, data: m)
    //     print(result)
    // }
    //
    // func testA() async throws {
    //     let seedPhrase = "slice sauce assist glimpse jelly trouble parent horror bread isolate uncle gallery owner angry rose fabric stable phrase much joke cotton mesh ancient erase"
    //     let result: Data = try Crypto.extractSymmetricKey(seedPhrase: seedPhrase)
    //     print(Base58.encode(result))
    //
    //     try await extractSeedPhrase2(phrase: seedPhrase, path: "")
    // }
}
