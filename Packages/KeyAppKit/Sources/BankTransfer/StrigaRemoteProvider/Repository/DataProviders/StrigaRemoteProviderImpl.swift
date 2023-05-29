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
    public func getUserDetails(
        userId: String
    ) async throws -> UserDetailsResponse {
        guard let authHeader else {
            throw NSError(domain: "", code: 0)
        }
        let endpoint = StrigaEndpoint.getUserDetails(authHeader: authHeader, userId: userId)
        return try await httpClient.request(endpoint: endpoint, responseModel: UserDetailsResponse.self)
    }
    
    public func createUser(
        model: CreateUserRequest
    ) async throws -> CreateUserResponse {
        guard let authHeader else {
            throw NSError(domain: "", code: 0)
        }
        let endpoint = StrigaEndpoint.createUser(authHeader: authHeader, model: model)
        return try await httpClient.request(endpoint: endpoint, responseModel: CreateUserResponse.self)
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
