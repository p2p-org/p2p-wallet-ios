import Foundation
import KeyAppNetworking
import SolanaSwift
import TweetNacl

public final class StrigaProvider {
    
    // Dependencies
    private let httpClient: IHTTPClient
    
    // MARK: - Init
    
    public init(httpClient: IHTTPClient) {
        self.httpClient = httpClient
    }
}

// MARK: - IStrigaProvider

extension StrigaProvider: IStrigaProvider {
    public func getUserDetails(
        authHeader: StrigaEndpoint.AuthHeader,
        userId: String
    ) async throws -> UserDetailsResponse {
        let endpoint = StrigaEndpoint.getUserDetails(authHeader: authHeader, userId: userId)
        return try await httpClient.request(endpoint: endpoint, responseModel: UserDetailsResponse.self)
    }
    
    public func createUser(
        authHeader: StrigaEndpoint.AuthHeader,
        model: CreateUserRequest
    ) async throws -> CreateUserResponse {
        let endpoint = StrigaEndpoint.createUser(authHeader: authHeader, model: model)
        return try await httpClient.request(endpoint: endpoint, responseModel: CreateUserResponse.self)
    }
    
    public func verifyMobileNumber(
        authHeader: StrigaEndpoint.AuthHeader,
        userId: String,
        verificationCode: String
    ) async throws {
        let endpoint = StrigaEndpoint.verifyMobileNumber(
            authHeader: authHeader,
            userId: userId,
            verificationCode: verificationCode
        )
        _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
    }
}
