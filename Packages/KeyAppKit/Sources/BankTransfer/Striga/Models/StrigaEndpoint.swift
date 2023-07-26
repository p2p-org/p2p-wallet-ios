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

    static func initiateOnchainFeeEstimate(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        sourceAccountId: String,
        whitelistedAddressId: String,
        amount: String
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/wallets/send/initiate/onchain/fee-estimate",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "sourceAccountId": sourceAccountId,
                "whitelistedAddressId": whitelistedAddressId,
                "amount": amount
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

    static func initiateOnChainWalletSend(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        sourceAccountId: String,
        whitelistedAddressId: String,
        amount: String,
        accountCreation: Bool = false
    ) throws -> Self {
        return try .init(
            baseURL: baseURL,
            path: "/wallets/send/initiate/onchain",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": .init(userId),
                "sourceAccountId": .init(sourceAccountId),
                "whitelistedAddressId": .init(whitelistedAddressId),
                "amount": .init(amount),
                "accountCreation": .init(accountCreation)
            ] as [String: KeyAppNetworking.AnyEncodable]
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
    
    static func enrichAccount(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        accountId: String
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/wallets/account/enrich",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "accountId": accountId
            ]
        )
    }

    static func transactionResendOTP(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        challengeId: String
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/wallets/transaction/resend-otp",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "challengeId": challengeId
            ]
        )
    }

    static func transactionConfirmOTP(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        challengeId: String,
        verificationCode: String,
        ip: String
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/wallets/transaction/confirm",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "challengeId": challengeId,
                "verificationCode": verificationCode,
                "ip": ip
            ]
        )
    }

    static func whitelistDestinationAddress(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        address: String,
        currency: String,
        network: String,
        label: String?
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/wallets/whitelist-address",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "address": address,
                "currency": currency,
                "network": network,
                "label": label
            ]
        )
    }

    static func getWhitelistedUserDestinations(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        currency: String?,
        label: String?,
        page: String?
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/wallets/get/whitelisted-addresses",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "currency": currency,
//                "label": label,
//                "page": page
            ]
        )
    }

    static func exchangeRates(
        baseURL: String,
        keyPair: KeyPair
    ) throws -> Self {
        try StrigaEndpoint(
            baseURL: baseURL,
            path: "/trade/rates",
            method: .post,
            keyPair: keyPair,
            body: nil
        )
    }

    static func initiateSEPAPayment(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        sourceAccountId: String,
        amount: String,
        iban: String,
        bic: String
    ) throws -> Self {
        try StrigaEndpoint(
            baseURL: baseURL,
            path: "/wallets/send/initiate/bank",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": .init(userId),
                "sourceAccountId": .init(sourceAccountId),
                "amount": .init(amount),
                "destination": .init(["iban": .init(iban),
                                      "bic": .init(bic)] as [String: KeyAppNetworking.AnyEncodable]),
            ] as [String: KeyAppNetworking.AnyEncodable]
        )
    }

    static func getAccountStatement(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        accountId: String,
        startDate: Date,
        endDate: Date,
        page: Int
    ) throws -> Self {
        try StrigaEndpoint(
            baseURL: baseURL,
            path: "/wallets/get/account/statement",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": .init(userId),
                "accountId": .init(accountId),
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
