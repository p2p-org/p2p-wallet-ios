// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import CryptoSwift
import Foundation
import SolanaSwift

enum CryptoError: Error {
    case secureRandomDataError
    case invalidMac
}

internal enum Crypto {
    internal struct EncryptedMetadata: Codable {
        let nonce: String
        let metadataCiphered: String

        enum CodingKeys: String, CodingKey {
            case nonce
            case metadataCiphered = "metadata_ciphered"
        }
    }

    internal static func extractSymmetricKey(seedPhrase: String) throws -> Data {
        Data(try extractSeedPhrase(phrase: seedPhrase, path: "m/44'/101'/0'/0'")
            .prefix(32))
    }

    static func encryptMetadata(seedPhrase: String, data: Data) throws -> EncryptedMetadata {
        let symmetricKey = try extractSymmetricKey(seedPhrase: seedPhrase)
        let iv = AES.randomIV(12)

        let (cipher, tag) = try AEADChaCha20Poly1305.encrypt(
            [UInt8](data),
            key: [UInt8](symmetricKey),
            iv: iv,
            authenticationHeader: []
        )

        let result = Data(cipher + tag)
        return EncryptedMetadata(
            nonce: Data(iv).base64EncodedString(),
            metadataCiphered: result.base64EncodedString()
        )
    }

    static func decryptMetadata(seedPhrase: String, encryptedMetadata: EncryptedMetadata) throws -> Data {
        let symmetricKey = try extractSymmetricKey(seedPhrase: seedPhrase)

        guard
            let ivData = Data(base64Encoded: encryptedMetadata.nonce),
            let cipher = Data(base64Encoded: encryptedMetadata.metadataCiphered)
        else {
            throw OnboardingError.decodingError("crypto.decryptMetadata")
        }
        
        let iv = [UInt8](ivData)
        let tagSize = 16

        let (box, status) = try AEADChaCha20Poly1305.decrypt(
            [UInt8](Data(cipher.prefix(cipher.count - tagSize))),
            key: [UInt8](symmetricKey),
            iv: iv,
            authenticationHeader: [],
            authenticationTag: cipher.suffix(tagSize)
        )

        guard status == true else { throw CryptoError.invalidMac }
        let data = Data(box)

        return data
    }

    private static func secureRandomData(count: Int) throws -> Data {
        var bytes = [Int8](repeating: 0, count: count)

        // Fill bytes with secure random data
        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            count,
            &bytes
        )

        // A status of errSecSuccess indicates success
        if status == errSecSuccess {
            // Convert bytes to Data
            let data = Data(bytes: bytes, count: count)
            return data
        } else {
            // Handle error
            throw CryptoError.secureRandomDataError
        }
    }
}
