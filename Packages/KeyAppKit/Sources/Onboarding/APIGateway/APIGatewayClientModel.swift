// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

struct APIGatewayGetMetadataParams: Codable {
    let solanaPublicKey: String
    let ethereumAddress: String
    let signature: String
    let timestampDevice: String
    
    enum CodingKeys: String, CodingKey {
        case solanaPublicKey = "solana_pubkey"
        case ethereumAddress = "ethereum_id"
        case signature
        case timestampDevice = "timestamp_device"
    }
}

struct APIGatewayRegisterWalletParams: Codable {
    let solanaPublicKey: String
    let ethereumAddress: String
    let phone: String
    let channel: String
    let signature: String
    let timestampDevice: String

    enum CodingKeys: String, CodingKey {
        case solanaPublicKey = "solana_pubkey"
        case ethereumAddress = "ethereum_id"
        case phone
        case channel
        case signature
        case timestampDevice = "timestamp_device"
    }
}

struct APIGatewayConfirmRegisterWalletParams: Codable {
    let solanaPublicKey: String
    let ethereumAddress: String
    let encryptedShare: String
    let encryptedPayload: String
    let encryptedMetadata: String
    let phone: String
    let phoneConfirmationCode: String
    let signature: String
    let timestampDevice: String

    enum CodingKeys: String, CodingKey {
        case solanaPublicKey = "solana_pubkey"
        case ethereumAddress = "ethereum_id"
        case phone
        case phoneConfirmationCode = "phone_confirmation_code"
        case encryptedShare = "encrypted_share"
        case encryptedPayload = "encrypted_payload"
        case encryptedMetadata = "encrypted_metadata"
        case signature
        case timestampDevice = "timestamp_device"
    }
}

struct APIGatewayRestoreWalletParams: Codable {
    let restoreId: String
    let phone: String
    // let appHash: String
    let channel: String
    let signature: String
    let timestampDevice: String

    enum CodingKeys: String, CodingKey {
        case restoreId = "restore_id"
        case phone
        // case appHash = "app_hash"
        case channel
        case signature
        case timestampDevice = "timestamp_device"
    }
}

struct APIGatewayConfirmRestoreWalletParams: Codable {
    let restoreId: String
    let phone: String
    let phoneConfirmationCode: String
    let signature: String
    let timestampDevice: String

    enum CodingKeys: String, CodingKey {
        case restoreId = "restore_id"
        case phone
        case phoneConfirmationCode = "phone_confirmation_code"
        case signature
        case timestampDevice = "timestamp_device"
    }
}

struct APIGatewayClientResult: Codable {
    let status: Bool
}

struct APIGatewayClientGetMetadataResult: Codable {
    let encryptedMetadata: String
    
    enum CodingKeys: String, CodingKey {
        case encryptedMetadata = "metadata"
    }
    
}

struct APIGatewayClientConfirmRestoreWalletResult: Codable {
    let status: Bool
    let solanaPublicKey: String
    let ethereumAddress: String

    /// Base64 encoded share
    let share: String

    /// Base64 encoded share
    let payload: String
    let metadata: String

    enum CodingKeys: String, CodingKey {
        case status
        case solanaPublicKey = "solana_pubkey"
        case ethereumAddress = "ethereum_id"
        case share
        case payload
        case metadata
    }
}
