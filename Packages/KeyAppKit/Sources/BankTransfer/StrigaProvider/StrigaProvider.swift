//
//  StrigaProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 15.05.2023.
//

import Foundation
import KeyAppNetworking

private typealias AuthHeader = StrigaEndpoint.AuthHeader

public final class StrigaProvider {
    
    // Dependencies
    private let httpClient: IHTTPClient
    
    // Properties
    private let authHeader: AuthHeader
    
    // MARK: - Init
    
    public init(
        httpClient: IHTTPClient,
        userPublicKey: String,
        signedMessage: String
    ) {
        self.httpClient = httpClient
        authHeader = AuthHeader(pubKey: userPublicKey, signedMessage: signedMessage)
    }
}

// MARK: - IStrigaProvider

extension StrigaProvider: IStrigaProvider {
    public func createUser(model: CreateUserRequest) async throws -> CreateUserResponse {
        let endpoint = StrigaEndpoint.createUser(authHeader: authHeader, model: model)
        return try await httpClient.request(endpoint: endpoint, responseModel: CreateUserResponse.self)
    }
    
    public func verifyMobileNumber(userId: String, verificationCode: String) async throws {
        let endpoint = StrigaEndpoint.verifyMobileNumber(
            authHeader: authHeader,
            userId: userId,
            verificationCode: verificationCode
        )
        _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
    }
}
