//
//  StrigaProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 15.05.2023.
//

import Foundation

final class StrigaProvider {
    
    // Dependencies
    private let httpClient: HttpClient
    
    // Properties
    private let apiKey: String
    private let authorization: String
    
    // MARK: - Init
    
    init(
        httpClient: HttpClient,
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
        _ = try await httpClient.sendRequest(endpoint: endpoint, responseModel: String.self)
    }
}
