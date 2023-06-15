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

// MARK: - StrigaProvider

extension StrigaRemoteProviderImpl: StrigaRemoteProvider {

    public func getKYCStatus(userId: String) async throws -> StrigaKYC {
        try await getUserDetails(userId: userId).KYC
    }
    
    public func getUserDetails(
        userId: String
    ) async throws -> StrigaUserDetailsResponse {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.getUserDetails(baseURL: baseURL, keyPair: keyPair, userId: userId)
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaUserDetailsResponse.self)
    }
    
    public func createUser(
        model: StrigaCreateUserRequest
    ) async throws -> StrigaCreateUserResponse {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.createUser(baseURL: baseURL, keyPair: keyPair, body: model)
        do {
            return try await httpClient.request(endpoint: endpoint, responseModel: StrigaCreateUserResponse.self)
        } catch HTTPClientError.invalidResponse(let response, let data) where response?.statusCode == 400 {
            if let error = try? JSONDecoder().decode(StrigaRemoteProviderError.self, from: data) {
                throw BankTransferError(rawValue: Int(error.errorCode ?? "") ?? -1) ?? HTTPClientError.invalidResponse(response, data)
            } else {
                throw HTTPClientError.invalidResponse(response, data)
            }
        }
    }
    
    public func verifyMobileNumber(
        userId: String,
        verificationCode: String
    ) async throws {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.verifyMobileNumber(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            verificationCode: verificationCode
        )
        do {
            _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
        } catch HTTPClientError.invalidResponse(let response, let data) {
            if response?.statusCode == 409,
               let error = try? JSONDecoder().decode(StrigaRemoteProviderError.self, from: data) {
                throw BankTransferError(rawValue: Int(error.errorCode ?? "") ?? -1) ?? HTTPClientError.invalidResponse(response, data)
            }
        }
    }

    public func resendSMS(userId: String) async throws {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.resendSMS(baseURL: baseURL, keyPair: keyPair, userId: userId)
        do {
            _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
        } catch HTTPClientError.invalidResponse(let response, let data) {
            if response?.statusCode == 409,
               let error = try? JSONDecoder().decode(StrigaRemoteProviderError.self, from: data) {
                throw BankTransferError(rawValue: Int(error.errorCode ?? "") ?? -1) ?? HTTPClientError.invalidResponse(response, data)
            }
        }
    }

    public func getKYCToken(userId: String) async throws -> String {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.getKYCToken(baseURL: baseURL, keyPair: keyPair, userId: userId)
        
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaUserGetTokenResponse.self)
            .token
    }
}

struct StrigaRemoteProviderError: Codable {
    let message: String?
    let errorCode: String?
    let errorDetails: String?
}
