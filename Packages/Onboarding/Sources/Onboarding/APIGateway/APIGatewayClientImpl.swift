// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import TweetNacl
import KeyAppKitCore

public struct BlockErrorData: Codable {
    public let cooldown_ttl: TimeInterval?

    public init(cooldown_ttl: TimeInterval?) {
        self.cooldown_ttl = cooldown_ttl
    }
}

public class APIGatewayClientImpl: APIGatewayClient {
    private let endpoint: URL
    private let networkManager: NetworkManager
    private let dateFormat: DateFormatter
    private let uuid = UUID()

    public init(endpoint: String, networkManager: NetworkManager = URLSession.shared) {
        self.endpoint = URL(string: endpoint)!
        self.networkManager = networkManager

        dateFormat = .init()
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSSSSZZZZZ"
        dateFormat.locale = Locale(identifier: "en_US_POSIX")
    }

    private func createDefaultRequest(method: String = "POST") -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.setValue("P2PWALLET_MOBILE", forHTTPHeaderField: "CHANNEL_ID")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }

    public func getMetadata(
        ethAddress: String,
        solanaPrivateKey: String,
        timestampDevice: Date
    ) async throws -> String {
        // Prepare
        var request = createDefaultRequest()
        let (solanaSecretKey, solanaPublicKey) = try prepare(solanaPrivateKey: solanaPrivateKey)

        // Create rpc request
        let rpcRequest = JSONRPCRequest(
            id: uuid.uuidString,
            method: "get_metadata",
            params: APIGatewayGetMetadataParams(
                solanaPublicKey: Base58.encode(solanaPublicKey),
                ethereumAddress: ethAddress,
                signature: try GetMetadataSignature(
                    ethereumAddress: ethAddress,
                    solanaPublicKey: Base58.encode(solanaPublicKey),
                    timestampDevice: Int64(timestampDevice.timeIntervalSince1970)
                ).signAsBase58(secretKey: solanaSecretKey),
                timestampDevice: dateFormat.string(from: timestampDevice)
            )
        )
        request.httpBody = try JSONEncoder().encode(rpcRequest)

        // Request
        let responseData = try await networkManager.requestData(request: request)
        let response = try JSONDecoder()
            .decode(JSONRPCResponse<APIGatewayClientGetMetadataResult, BlockErrorData>.self, from: responseData)
        if let error = response.error {
            throw apiGatewayError(from: error)
        }

        guard let result = response.result?.encryptedMetadata else { throw APIGatewayError.failedSending }
        return try result.fromBase64()
    }

    private func prepare(solanaPrivateKey: String) throws -> (solanaSecretKey: Data, solanaPublicKey: Data) {
        let solanaSecretKey = Data(Base58.decode(solanaPrivateKey))
        let solanaKeypair = try NaclSign.KeyPair.keyPair(fromSecretKey: solanaSecretKey)
        return (solanaSecretKey: solanaSecretKey, solanaPublicKey: solanaKeypair.publicKey)
    }

    public func registerWallet(
        solanaPrivateKey: String,
        ethAddress: String,
        phone: String,
        channel: APIGatewayChannel,
        timestampDevice: Date
    ) async throws {
        guard E164Numbers.validate(phone) else { throw APIGatewayError.invalidE164NumberStandard }

        // Prepare
        var request = createDefaultRequest()
        let (solanaSecretKey, solanaPublicKey) = try prepare(solanaPrivateKey: solanaPrivateKey)

        // Create rpc request
        let rpcRequest = JSONRPCRequest(
            id: uuid.uuidString,
            method: "register_wallet",
            params: APIGatewayRegisterWalletParams(
                solanaPublicKey: Base58.encode(solanaPublicKey),
                ethereumAddress: ethAddress,
                phone: phone,
                channel: channel.rawValue,
                signature: try RegisterWalletSignature(
                    solanaPublicKey: Base58.encode(solanaPublicKey),
                    ethereumAddress: ethAddress,
                    phone: phone,
                    appHash: "",
                    channel: channel.rawValue
                ).signAsBase58(secretKey: solanaSecretKey),
                timestampDevice: dateFormat.string(from: timestampDevice)
            )
        )

        request.httpBody = try JSONEncoder().encode(rpcRequest)

        // Request
        let responseData = try await networkManager.requestData(request: request)

        // Check result
        let result = try JSONDecoder().decode(JSONRPCResponse<APIGatewayClientResult, BlockErrorData>.self, from: responseData)
        if let error = result.error {
            throw apiGatewayError(from: error)
        } else if result.result?.status != true {
            throw APIGatewayError.failedSending
        }
    }

    public func confirmRegisterWallet(
        solanaPrivateKey: String,
        ethAddress: String,
        share: String,
        encryptedPayload: String,
        encryptedMetaData: String,
        phone: String,
        otpCode: String,
        timestampDevice: Date
    ) async throws {
        guard E164Numbers.validate(phone) else { throw APIGatewayError.invalidE164NumberStandard }

        // Prepare
        var request = createDefaultRequest()
        let (solanaSecretKey, solanaPublicKey) = try prepare(solanaPrivateKey: solanaPrivateKey)

        // Create rpc request
        let rpcRequest = JSONRPCRequest(
            id: uuid.uuidString,
            method: "confirm_register_wallet",
            params: APIGatewayConfirmRegisterWalletParams(
                solanaPublicKey: Base58.encode(solanaPublicKey),
                ethereumAddress: ethAddress,
                encryptedShare: share.base64(),
                encryptedPayload: encryptedPayload.base64(),
                encryptedMetadata: encryptedMetaData.base64(),
                phone: phone,
                phoneConfirmationCode: otpCode,
                signature: try ConfirmRegisterWalletSignature(
                    ethereumId: ethAddress,
                    solanaPublicKey: Base58.encode(solanaPublicKey),
                    encryptedShare: share,
                    encryptedPayload: encryptedPayload,
                    encryptedMetadata: encryptedMetaData,
                    phone: phone,
                    phoneConfirmationCode: otpCode
                ).signAsBase58(secretKey: solanaSecretKey),
                timestampDevice: dateFormat.string(from: timestampDevice)
            )
        )

        request.httpBody = try JSONEncoder().encode(rpcRequest)

        // Request
        let responseData = try await networkManager.requestData(request: request)

        // Check result
        let result = try JSONDecoder().decode(JSONRPCResponse<APIGatewayClientResult, BlockErrorData>.self, from: responseData)
        if let error = result.error {
            throw apiGatewayError(from: error)
        } else if result.result?.status != true {
            throw APIGatewayError.failedSending
        }
    }

    public func restoreWallet(
        solPrivateKey: Data,
        phone: String,
        channel: BindingPhoneNumberChannel,
        timestampDevice: Date
    ) async throws {
        guard E164Numbers.validate(phone) else { throw APIGatewayError.invalidE164NumberStandard }

        var request = createDefaultRequest()
        let solanaKeypair = try NaclSign.KeyPair.keyPair(fromSecretKey: solPrivateKey)

        let rpcRequest = JSONRPCRequest(
            id: uuid.uuidString,
            method: "restore_wallet",
            params: APIGatewayRestoreWalletParams(
                restoreId: Base58.encode(solanaKeypair.publicKey),
                phone: phone,
                // appHash: "",
                channel: channel.rawValue,
                signature: try RestoreWalletSignature(
                    restoreId: Base58.encode(solanaKeypair.publicKey),
                    phone: phone,
                    appHash: "",
                    channel: channel.rawValue
                ).signAsBase58(secretKey: solPrivateKey),
                timestampDevice: dateFormat.string(from: timestampDevice)
            )
        )

        request.httpBody = try JSONEncoder().encode(rpcRequest)

        // Request
        let responseData = try await networkManager.requestData(request: request)

        // Check result
        let result = try JSONDecoder().decode(JSONRPCResponse<APIGatewayClientResult, BlockErrorData>.self, from: responseData)
        if let error = result.error {
            throw apiGatewayError(from: error)
        } else if result.result?.status != true {
            throw APIGatewayError.failedSending
        }
    }

    public func confirmRestoreWallet(
        solanaPrivateKey: Data,
        phone: String,
        otpCode: String,
        timestampDevice: Date
    ) async throws -> APIGatewayRestoreWalletResult {
        guard E164Numbers.validate(phone) else { throw APIGatewayError.invalidE164NumberStandard }

        var request = createDefaultRequest()
        let solanaKeypair = try NaclSign.KeyPair.keyPair(fromSecretKey: solanaPrivateKey)

        let rpcRequest = JSONRPCRequest(
            id: uuid.uuidString,
            method: "confirm_restore_wallet",
            params: APIGatewayConfirmRestoreWalletParams(
                restoreId: Base58.encode(solanaKeypair.publicKey),
                phone: phone,
                phoneConfirmationCode: otpCode,
                signature: try ConfirmRestoreWalletSignature(
                    restoreId: Base58.encode(solanaKeypair.publicKey),
                    phone: phone,
                    phoneConfirmationCode: otpCode
                ).signAsBase58(secretKey: solanaPrivateKey),
                timestampDevice: dateFormat.string(from: timestampDevice)
            )
        )

        request.httpBody = try JSONEncoder().encode(rpcRequest)

        // Request
        let responseData = try await networkManager.requestData(request: request)

        // Check result
        let response = try JSONDecoder()
            .decode(JSONRPCResponse<APIGatewayClientConfirmRestoreWalletResult, BlockErrorData>.self, from: responseData)
        if let error = response.error {
            throw apiGatewayError(from: error)
        } else if response.result?.status != true {
            throw APIGatewayError.failedSending
        }

        guard let result = response.result else { throw APIGatewayError.failedSending }
        return .init(
            solanaPublicKey: result.solanaPublicKey,
            ethereumId: result.ethereumAddress,
            encryptedShare: try result.share.fromBase64(),
            encryptedPayload: try result.payload.fromBase64(),
            encryptedMetaData: try result.metadata.fromBase64()
        )
    }

    private func apiGatewayError(from error: JSONRPCError<BlockErrorData>) -> Error {
        let definedError = APIGatewayError(rawValue: error.code)
        if definedError == .wait10Min, let cooldown = error.data?.cooldown_ttl {
            return APIGatewayCooldownError(cooldown: cooldown)
        }
        return definedError ?? UndefinedAPIGatewayError(code: error.code)
    }
}

private extension String {
    func base64() -> String {
        Data(utf8).base64EncodedString()
    }

    func fromBase64() throws -> String {
        guard
            let data = Data(base64Encoded: self),
            let result = String(data: data, encoding: .utf8)
        else {
            throw APIGatewayError.failedConvertingFromBase64
        }

        return result
    }
}
