import Foundation
import KeyAppNetworking
import SolanaSwift
import TweetNacl

public final class StrigaRemoteProviderImpl {
    
    // Dependencies
    private let httpClient: IHTTPClient
    private let keyPair: KeyPair?
    
    // MARK: - Init
    
    public init(
        solanaKeyPair keyPair: KeyPair?,
        httpClient: IHTTPClient = HTTPClient()
    ) {
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
        guard let authHeader else {
            throw NSError(domain: "", code: 0)
        }
        let endpoint = StrigaEndpoint.getUserDetails(authHeader: authHeader, userId: userId)
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaUserDetailsResponse.self)
    }
    
    public func createUser(
        model: StrigaCreateUserRequest
    ) async throws -> StrigaCreateUserResponse {
        guard let authHeader else {
            throw NSError(domain: "", code: 0)
        }
        let endpoint = StrigaEndpoint.createUser(authHeader: authHeader, model: model)
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaCreateUserResponse.self)
    }
    
    public func verifyMobileNumber(
        userId: String,
        verificationCode: String
    ) async throws {
        guard let authHeader else {
            throw NSError(domain: "", code: 0)
        }
        let endpoint = StrigaEndpoint.verifyMobileNumber(
            authHeader: authHeader,
            userId: userId,
            verificationCode: verificationCode
        )
        _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
    }
    
    public func resendSMS(userId: String) async throws {
        guard let authHeader else { throw NSError(domain: "", code: 0) }
        let endpoint = StrigaEndpoint.resendSMS(authHeader: authHeader, userId: userId)
        _ = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
    }
    
    public func getKYCToken(userId: String) async throws -> String {
        guard let authHeader else { throw NSError(domain: "", code: 0) }
        let endpoint = StrigaEndpoint.kycGetToken(authHeader: authHeader, userId: userId)
        
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaUserGetTokenResponse.self)
            .token
    }
}

// MARK: - Helpers

private typealias AuthHeader = StrigaEndpoint.AuthHeader

private extension StrigaRemoteProviderImpl {
    var authHeader: AuthHeader? {
        guard let keyPair, let signedMessage = getSignedTimestampMessage(keyPair: keyPair) else { return nil }
        return AuthHeader(pubKey: keyPair.publicKey.base58EncodedString, signedMessage: signedMessage)
    }
    
    func getSignedTimestampMessage(keyPair: KeyPair) -> String? {
        // get timestamp
        let timestamp = "\(Int(NSDate().timeIntervalSince1970) * 1_000)"
        
        // form message
        guard
            let data = timestamp.data(using: .utf8),
            let signedTimestampMessage = try? NaclSign.signDetached(
                message: data,
                secretKey: keyPair.secretKey
            ).base64EncodedString()
        else { return nil }
        // return unixtime:signature_of_unixtime_by_user_privatekey_in_base64_format
        return [timestamp, signedTimestampMessage].joined(separator: ":")
    }
}
