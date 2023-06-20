import Foundation
import KeyAppNetworking
import KeyAppKitCore
import SolanaSwift
import TweetNacl

/// Endpoint type for striga
struct StrigaEndpoint: HTTPEndpoint {

    // MARK: - Properties

    let baseURL: String
    let path: String
    let method: KeyAppNetworking.HTTPMethod
    let keyPair: KeyPair
    let header: [String : String]
    let body: String?
    
    // MARK: - Initializer

    private init(
        version: Int = 1,
        baseURL: String,
        path: String,
        method: HTTPMethod,
        keyPair: KeyPair,
        body: Encodable?
    ) throws {
        self.baseURL = baseURL
        self.path = "/v\(version)" + path
        self.method = method
        self.keyPair = keyPair
        self.header = [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": try keyPair.getSignedTimestampMessage()
        ]
        self.body = body?.encoded
    }

    // MARK: - Factory methods

    static func getKYC(
        baseURL: String,
        keyPair: KeyPair,
        userId: String
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/user/kyc/\(userId)",
            method: .get,
            keyPair: keyPair,
            body: nil
        )
    }

    static func verifyMobileNumber(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        verificationCode: String
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/user/verify-mobile",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "verificationCode": verificationCode
            ]
        )
    }
    
    static func getUserDetails(
        baseURL: String,
        keyPair: KeyPair,
        userId: String
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/user/\(userId)",
            method: .get,
            keyPair: keyPair,
            body: nil
        )
    }
    
    static func createUser(
        baseURL: String,
        keyPair: KeyPair,
        body: StrigaCreateUserRequest
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/user/create",
            method: .post,
            keyPair: keyPair,
            body: body
        )
    }
    
    static func resendSMS(
        baseURL: String,
        keyPair: KeyPair,
        userId: String
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/user/resend-sms",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId
            ]
        )
    }
    
    static func getKYCToken(
        baseURL: String,
        keyPair: KeyPair,
        userId: String
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/user/kyc/start",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId
            ]
        )
    }

    static func getAllWallets(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        startDate: Date,
        endDate: Date,
        page: Int
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/wallets/get/all",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": .init(userId),
                "startDate": .init(startDate.millisecondsSince1970),
                "endDate": .init(endDate.millisecondsSince1970),
                "page": .init(page)
            ] as [String: KeyAppNetworking.AnyEncodable]
        )
    }
}

extension KeyPair {
    func getSignedTimestampMessage(date: NSDate = NSDate()) throws -> String {
        // get timestamp
        let timestamp = "\(Int(date.timeIntervalSince1970) * 1_000)"
        
        // form message
        guard
            let data = timestamp.data(using: .utf8),
            let signedTimestampMessage = try? NaclSign.signDetached(
                message: data,
                secretKey: secretKey
            ).base64EncodedString()
        else {
            throw BankTransferError.invalidKeyPair
        }
        // return unixtime:signature_of_unixtime_by_user_privatekey_in_base64_format
        return [timestamp, signedTimestampMessage].joined(separator: ":")
    }
}

// MARK: - Encoding

private extension Encodable {
    /// Encoded string for request as a json string
    var encoded: String? {
        encoded(strategy: .useDefaultKeys)
    }
    
    func encoded(strategy: JSONEncoder.KeyEncodingStrategy) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.keyEncodingStrategy = strategy
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
