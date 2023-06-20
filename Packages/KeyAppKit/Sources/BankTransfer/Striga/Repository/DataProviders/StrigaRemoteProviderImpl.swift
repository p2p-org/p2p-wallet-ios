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
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.getKYC(baseURL: baseURL, keyPair: keyPair, userId: userId)
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaKYC.self)
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
            let response = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
            // expect response to be Accepted
            guard response == "Accepted" else {
                throw HTTPClientError.invalidResponse(nil, response.data(using: .utf8) ?? Data())
            }
            return
        } catch HTTPClientError.invalidResponse(let response, let data) {
            if response?.statusCode == 409 {
                let error = try JSONDecoder().decode(StrigaRemoteProviderError.self, from: data)
                throw BankTransferError(rawValue: Int(error.errorCode ?? "") ?? -1) ?? HTTPClientError.invalidResponse(response, data)
            }
            throw HTTPClientError.invalidResponse(response, data)
        }
    }

    public func resendSMS(userId: String) async throws {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.resendSMS(baseURL: baseURL, keyPair: keyPair, userId: userId)
        do {
            let response = try await httpClient.request(endpoint: endpoint, responseModel: String.self)
            // expect response to be Accepted
            guard response == "Ok" else {
                throw HTTPClientError.invalidResponse(nil, response.data(using: .utf8) ?? Data())
            }
            return
        } catch HTTPClientError.invalidResponse(let response, let data) {
            if response?.statusCode == 409,
               let error = try? JSONDecoder().decode(StrigaRemoteProviderError.self, from: data),
               error.errorCode == "00002"
            {
                throw BankTransferError.mobileAlreadyVerified
            }
            throw HTTPClientError.invalidResponse(response, data)
        }
    }

    public func initiateOnChainWalletSend(
        userId: String,
        sourceAccountId: String,
        whitelistedAddressId: String,
        amount: String
    ) async throws -> StrigaWalletSendResponse {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.initiateOnChainWalletSend(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            sourceAccountId: sourceAccountId,
            whitelistedAddressId: whitelistedAddressId,
            amount: amount
        )
        return try await httpClient.request(
            endpoint: endpoint,
            responseModel: StrigaWalletSendResponse.self
        )
    }

    public func getKYCToken(userId: String) async throws -> String {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.getKYCToken(baseURL: baseURL, keyPair: keyPair, userId: userId)
        
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaUserGetTokenResponse.self)
            .token
    }

    public func getAllWalletsByUser(userId: String, startDate: Date, endDate: Date, page: Int) async throws -> StrigaGetAllWalletsResponse {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.getAllWallets(baseURL: baseURL, keyPair: keyPair, userId: userId, startDate: startDate, endDate: endDate, page: page)
        
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaGetAllWalletsResponse.self)
    }
    
    public func enrichAccount(userId: String, accountId: String) async throws -> StrigaEnrichedAccountResponse {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.enrichAccount(baseURL: baseURL, keyPair: keyPair, userId: userId, accountId: accountId)
        
        return try await httpClient.request(endpoint: endpoint, responseModel: StrigaEnrichedAccountResponse.self)
    }

    public func transactionResendOTP(
        userId: String,
        challangeId: String
    ) async throws -> StrigaTransactionResendOTPResponse {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.transactionResendOTP(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            challengeId: challangeId
        )
        return try await httpClient.request(
            endpoint: endpoint,
            responseModel: StrigaTransactionResendOTPResponse.self
        )
    }

    public func transactionConfirmOTP(
        userId: String,
        challangeId: String,
        code: String,
        ip: String
    ) async throws -> StrigaTransactionConfirmOTPResponse {
        guard let keyPair else { throw BankTransferError.invalidKeyPair }
        let endpoint = try StrigaEndpoint.transactionConfirmOTP(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            challengeId: challangeId,
            verificationCode: code,
            ip: ip
        )
        return try await httpClient.request(
            endpoint: endpoint,
            responseModel: StrigaTransactionConfirmOTPResponse.self
        )
    }

}

// MARK: - Error response

struct StrigaRemoteProviderError: Codable {
    let errorCode: String?
}
