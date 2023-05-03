// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import TweetNacl

public protocol Signature: BorshSerializable {
    func sign(secretKey: Data) throws -> Data
}

public extension Signature {
    func sign(secretKey: Data) throws -> Data {
        var data = Data()
        try serialize(to: &data)
        return try NaclSign.signDetached(message: data, secretKey: secretKey)
    }

    func signAsBase58(secretKey: Data) throws -> String {
        Base58.encode(try sign(secretKey: secretKey))
    }
}

struct GetMetadataSignature: Signature {
    let ethereumAddress: String
    let solanaPublicKey: String
    let timestampDevice: Int64

    func serialize(to writer: inout Data) throws {
        try ethereumAddress.serialize(to: &writer)
        try solanaPublicKey.serialize(to: &writer)
        try timestampDevice.serialize(to: &writer)
    }
}

struct RegisterWalletSignature: Signature {
    let solanaPublicKey: String
    let ethereumAddress: String
    let phone: String
    let appHash: String
    let channel: String

    func serialize(to writer: inout Data) throws {
        try ethereumAddress.serialize(to: &writer)
        try solanaPublicKey.serialize(to: &writer)
        try phone.serialize(to: &writer)
        try appHash.serialize(to: &writer)
        try channel.serialize(to: &writer)
    }
}

struct ConfirmRegisterWalletSignature: Signature {
    let ethereumId: String
    let solanaPublicKey: String
    let encryptedShare: String
    let encryptedPayload: String
    let encryptedMetadata: String
    let phone: String
    let phoneConfirmationCode: String

    func serialize(to writer: inout Data) throws {
        try ethereumId.serialize(to: &writer)
        try solanaPublicKey.serialize(to: &writer)
        try encryptedShare.serialize(to: &writer)
        try encryptedPayload.serialize(to: &writer)
        try encryptedMetadata.serialize(to: &writer)
        try phone.serialize(to: &writer)
        try phoneConfirmationCode.serialize(to: &writer)
    }
}

struct RestoreWalletSignature: Signature {
    let restoreId: String
    let phone: String
    let appHash: String
    let channel: String

    func serialize(to writer: inout Data) throws {
        try restoreId.serialize(to: &writer)
        try phone.serialize(to: &writer)
        try appHash.serialize(to: &writer)
        try channel.serialize(to: &writer)
    }
}

struct ConfirmRestoreWalletSignature: Signature {
    let restoreId: String
    let phone: String
    let phoneConfirmationCode: String

    func serialize(to writer: inout Data) throws {
        try restoreId.serialize(to: &writer)
        try phone.serialize(to: &writer)
        try phoneConfirmationCode.serialize(to: &writer)
    }
}
