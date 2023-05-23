//
//  StrigaProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 15.05.2023.
//

import Foundation
import KeyAppNetworking

final class StrigaProvider {
    
    // Dependencies
    private let httpClient: IHTTPClient
    
    // Properties
    private let apiKey: String
    private let authorization: String
    
    // MARK: - Init
    
    init(
        httpClient: IHTTPClient,
        apiKey: String,
        authorization: String
    ) {
        self.httpClient = httpClient
        self.apiKey = apiKey
        self.authorization = authorization
    }
}

// MARK: - IStrigaProvider

extension StrigaProvider: IStrigaProvider {
    func verifyMobileNumber(userId: String, verificationCode: String) async throws {
        let endpoint = StrigaEndpoint.verifyMobileNumber(userId: userId, verificationCode: verificationCode)
        _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
    }
}
