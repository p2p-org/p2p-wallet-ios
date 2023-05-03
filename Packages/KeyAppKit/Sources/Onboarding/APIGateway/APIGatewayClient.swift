// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public struct APIGatewayCooldownError: Error {
    let cooldown: TimeInterval
}

public enum APIGatewayError: Int, Error, CaseIterable {
    case invalidOTP = -32061
    case wait10Min = -32053
    case invalidSignature = -32058
    case parseError = -32700
    case invalidRequest = -32600
    case methodNotFound = -32601
    case invalidParams = -32602
    case internalError = -32603
    case everythingIsBroken = -32052
    case retry = -32050
    case changePhone = -32054
    case alreadyConfirmed = -32051
    case callNotPermit = -32055
    case publicKeyExists = -32056
    case publicKeyAndPhoneExists = -32057
    case youRequestOTPTooOften = -32059
    case notVerified = -32060

    case invalidE164NumberStandard = -40000
    case failedSending = -40001
    case failedConvertingFromBase64 = -40002
}

public struct UndefinedAPIGatewayError: Error {
    public var _code: Int

    public init(code: Int) {
        _code = code
    }
}

public enum APIGatewayChannel: String, Codable {
    case sms
    case call
}

public struct APIGatewayRestoreWalletResult: Codable, Equatable {
    let solanaPublicKey: String
    let ethereumId: String
    let encryptedShare: String
    let encryptedPayload: String
    let encryptedMetaData: String
}

public struct APIGatewayMetaData: Codable, Equatable {
    public let deviceName: String
    public let phoneNumber: String
    public let email: String
    public let authProvider: String
}

public protocol APIGatewayClient {
    /// Get metadata from api gateway
    ///
    /// - Parameters:
    ///   - ethAddress: Ethereum address.
    ///   - solanaPrivateKey: Base58 key.
    ///   - timestampDevice: Timestamp of request.
    /// - Returns: Encrypted base64 metadata
    /// - Throws:
    func getMetadata(ethAddress: String, solanaPrivateKey: String, timestampDevice: Date) async throws -> String

    /// Binding a phone number to solana wallet
    ///
    /// - Parameters:
    ///   - solanaPrivateKey: Base58 key.
    ///   - ethAddress: Ethereum address.
    ///   - phone: E.164 phone number format.
    ///   - channel: The channel through which the otp code will be delivered.
    ///   - timestampDevice: Timestamp of request.
    /// - Throws: ``APIGatewayError``
    func registerWallet(
        solanaPrivateKey: String,
        ethAddress: String,
        phone: String,
        channel: APIGatewayChannel,
        timestampDevice: Date
    ) async throws

    /// Confirm binding by delivered otp code.
    ///
    /// - Parameters:
    ///   - solanaPrivateKey: Base58 key.
    ///   - ethAddress: Ethereum address.
    ///   - share: TKey share.
    ///   - encryptedPayload: Encrypted mnemonic (base64).
    ///   - encryptedMetaData: Encrypted metadata
    ///   - phone: E.164 phone number format.
    ///   - otpCode: delivered OTP code
    ///   - timestampDevice:
    func confirmRegisterWallet(
        solanaPrivateKey: String,
        ethAddress: String,
        share: String,
        encryptedPayload: String,
        encryptedMetaData: String,
        phone: String,
        otpCode: String,
        timestampDevice: Date
    ) async throws

    /// Restore wallet by using phone number.
    ///
    /// The user will get a share after success confirmation (by calling ``confirmRestoreWallet``).
    /// - Parameters:
    ///   - solPrivateKey: Solana private key
    ///   - phone: E.164 phone number format.
    ///   - channel: OTP delivery channel
    ///   - timestampDevice:
    func restoreWallet(
        solPrivateKey: Data,
        phone: String,
        channel: BindingPhoneNumberChannel,
        timestampDevice: Date
    ) async throws

    /// Confirm restore by sending otp code.
    ///
    /// The user will get a share after success confirmation.
    /// - Parameters:
    ///   - solanaPrivateKey:
    ///   - phone: E.164 phone number format.
    ///   - otpCode: delivered OTP code
    ///   - timestampDevice:
    func confirmRestoreWallet(
        solanaPrivateKey: Data,
        phone: String,
        otpCode: String,
        timestampDevice: Date
    ) async throws -> APIGatewayRestoreWalletResult

    func isValidOTPFormat(code: String) -> Bool
}

public extension APIGatewayClient {
    func isValidOTPFormat(code: String) -> Bool { code.count == 6 }
}
