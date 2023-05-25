//
//  StrigaProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 15.05.2023.
//

import Foundation
import KeyAppNetworking
import SolanaSwift
import TweetNacl

private typealias AuthHeader = StrigaEndpoint.AuthHeader

public final class StrigaProvider {
    
    // Dependencies
    private let httpClient: IHTTPClient
    
    // Properties
    private let keyPair: KeyPair
    
    // MARK: - Init
    
    public init(
        httpClient: IHTTPClient,
        keyPair: KeyPair
    ) {
        self.httpClient = httpClient
        self.keyPair = keyPair
    }
}

// MARK: - IStrigaProvider

extension StrigaProvider: IStrigaProvider {
    public func createUser(model: CreateUserRequest) async throws -> CreateUserResponse {
        guard let authHeader = authHeader() else { throw HTTPClientError.unknown }
        let endpoint = StrigaEndpoint.createUser(authHeader: authHeader, model: model)
        return try await httpClient.request(endpoint: endpoint, responseModel: CreateUserResponse.self)
    }
    
    public func verifyMobileNumber(userId: String, verificationCode: String) async throws {
        guard let authHeader = authHeader() else { throw HTTPClientError.unknown }
        let endpoint = StrigaEndpoint.verifyMobileNumber(
            authHeader: authHeader,
            userId: userId,
            verificationCode: verificationCode
        )
        _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
    }
}

// MARK: - Auth Headers

private extension StrigaProvider {
    func authHeader() -> AuthHeader? {
        guard let signedMessage = getSignedTimestampMessage(userKeyPair: keyPair) else { return nil }
        return AuthHeader(pubKey: keyPair.publicKey.base58EncodedString, signedMessage: signedMessage)
    }
    
    func getSignedTimestampMessage(userKeyPair: KeyPair) -> String? {
        // get timestamp
        let timestamp = "\(Int(NSDate().timeIntervalSince1970) * 1_000)"
        
        // form message
        guard
            let data = timestamp.data(using: .utf8),
            let signedTimestampMessage = try? NaclSign.signDetached(
                message: data,
                secretKey: userKeyPair.secretKey
            ).base64EncodedString()
        else { return nil }
        // return unixtime:signature_of_unixtime_by_user_privatekey_in_base64_format
        return [timestamp, signedTimestampMessage].joined(separator: ":")
    }
}
