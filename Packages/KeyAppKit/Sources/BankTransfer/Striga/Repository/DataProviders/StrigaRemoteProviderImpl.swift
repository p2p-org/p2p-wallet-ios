import Foundation
import KeyAppNetworking
import SolanaSwift
import TweetNacl

public final class StrigaRemoteProviderImpl {
    
    // Dependencies
    private let httpClient: IHTTPClient
    private let keyPair: KeyPair?
    private let baseURL: String
    
    // MARK: - Init
    
    public init(
        baseURL: String,
        solanaKeyPair keyPair: KeyPair?,
        httpClient: IHTTPClient = HTTPClient()
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.keyPair = keyPair
    }
}

// MARK: - IStrigaProvider

extension StrigaRemoteProviderImpl: StrigaRemoteProvider {
    
    public func getUserId() async throws -> String? {
        fatalError("Implementing")
    }
    
    public func getKYCStatus() async throws -> StrigaCreateUserResponse.KYC {
        fatalError("Implementing")
    }
    
    public func getUserDetails(
        userId: String
    ) async throws -> StrigaUserDetailsResponse {
        guard let keyPair else { throw BankTransferServiceError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.getUserDetails(baseURL: baseURL, keyPair: keyPair, userId: userId)
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaUserDetailsResponse.self)
    }
    
    public func createUser(
        model: StrigaCreateUserRequest
    ) async throws -> StrigaCreateUserResponse {
        guard let keyPair else { throw BankTransferServiceError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.createUser(baseURL: baseURL, keyPair: keyPair, body: model)
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaCreateUserResponse.self)
    }
    
    public func verifyMobileNumber(
        userId: String,
        verificationCode: String
    ) async throws {
        guard let keyPair else { throw BankTransferServiceError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.verifyMobileNumber(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            verificationCode: verificationCode
        )
        _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
    }
    
    public func resendSMS(userId: String) async throws {
        guard let keyPair else { throw BankTransferServiceError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.resendSMS(baseURL: baseURL, keyPair: keyPair, userId: userId)
        _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
    }
    
    public func getKYCToken(userId: String) async throws -> String {
        guard let keyPair else { throw BankTransferServiceError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.getKYCToken(baseURL: baseURL, keyPair: keyPair, userId: userId)
        
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaUserGetTokenResponse.self)
            .token
    }
}
