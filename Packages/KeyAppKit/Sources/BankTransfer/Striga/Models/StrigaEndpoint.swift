import Foundation
import KeyAppKitCore
import KeyAppNetworking
import SolanaSwift
import TweetNacl

/// Endpoint type for striga
struct StrigaEndpoint: HTTPEndpoint {
    // MARK: - Properties

    let baseURL: String
    let path: String
    let method: KeyAppNetworking.HTTPMethod
    let keyPair: KeyPair
    let header: [String: String]
    let body: String?

    // MARK: - Initializer

    private init(
        baseURL: String,
        path: String,
        method: HTTPMethod,
        keyPair: KeyPair,
        body: Encodable?,
        timestamp: NSDate = NSDate()
    ) throws {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.keyPair = keyPair
        header = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        self.body = body?.encoded
    }

    // MARK: - Factory methods

    static func getKYC(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/user/kyc/\(userId)",
            method: .get,
            keyPair: keyPair,
            body: nil,
            timestamp: timestamp
        )
    }

    static func verifyMobileNumber(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        verificationCode: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/user/verify-mobile",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "verificationCode": verificationCode,
            ],
            timestamp: timestamp
        )
    }

    static func initiateOnchainFeeEstimate(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        sourceAccountId: String,
        whitelistedAddressId: String,
        amount: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "striga/api/v1/wallets/send/initiate/onchain/fee-estimate",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "sourceAccountId": sourceAccountId,
                "whitelistedAddressId": whitelistedAddressId,
                "amount": amount,
            ],
            timestamp: timestamp
        )
    }

    static func getUserDetails(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/user/\(userId)",
            method: .get,
            keyPair: keyPair,
            body: nil,
            timestamp: timestamp
        )
    }

    static func createUser(
        baseURL: String,
        keyPair: KeyPair,
        body: StrigaCreateUserRequest,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/api/v1/user/create",
            method: .post,
            keyPair: keyPair,
            body: body,
            timestamp: timestamp
        )
    }

    static func resendSMS(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/user/resend-sms",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
            ],
            timestamp: timestamp
        )
    }

    static func initiateOnChainWalletSend(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        sourceAccountId: String,
        whitelistedAddressId: String,
        amount: String,
        accountCreation: Bool = false,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/api/v1/wallets/send/initiate/onchain",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": .init(userId),
                "sourceAccountId": .init(sourceAccountId),
                "whitelistedAddressId": .init(whitelistedAddressId),
                "amount": .init(amount),
                "accountCreation": .init(accountCreation),
            ] as [String: KeyAppNetworking.AnyEncodable],
            timestamp: timestamp
        )
    }

    static func getKYCToken(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/user/kyc/start",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
            ],
            timestamp: timestamp
        )
    }

    static func getAllWallets(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        startDate: Date,
        endDate: Date,
        page: Int,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/wallets/get/all",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": .init(userId),
                "startDate": .init(startDate.millisecondsSince1970),
                "endDate": .init(endDate.millisecondsSince1970),
                "page": .init(page),
            ] as [String: KeyAppNetworking.AnyEncodable],
            timestamp: timestamp
        )
    }

    static func enrichAccount(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        accountId: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/wallets/account/enrich",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "accountId": accountId,
            ],
            timestamp: timestamp
        )
    }

    static func transactionResendOTP(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        challengeId: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/wallets/transaction/resend-otp",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "challengeId": challengeId,
            ],
            timestamp: timestamp
        )
    }

    static func transactionConfirmOTP(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        challengeId: String,
        verificationCode: String,
        ip: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/wallets/transaction/confirm",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "challengeId": challengeId,
                "verificationCode": verificationCode,
                "ip": ip,
            ],
            timestamp: timestamp
        )
    }

    static func whitelistDestinationAddress(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        address: String,
        currency: String,
        network: String,
        label: String?,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/wallets/whitelist-address",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "address": address,
                "currency": currency,
                "network": network,
                "label": label,
            ],
            timestamp: timestamp
        )
    }

    static func getWhitelistedUserDestinations(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        currency: String?,
        label _: String?,
        page _: String?,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try .init(
            baseURL: baseURL,
            path: "/striga/api/v1/wallets/get/whitelisted-addresses",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": userId,
                "currency": currency,
//                "label": label,
//                "page": page
            ],
            timestamp: timestamp
        )
    }

    static func exchangeRates(
        baseURL: String,
        keyPair: KeyPair,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try StrigaEndpoint(
            baseURL: baseURL,
            path: "/striga/api/v1/trade/rates",
            method: .post,
            keyPair: keyPair,
            body: nil,
            timestamp: timestamp
        )
    }

    static func initiateSEPAPayment(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        sourceAccountId: String,
        amount: String,
        iban: String,
        bic: String,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try StrigaEndpoint(
            baseURL: baseURL,
            path: "/striga/api/v1/wallets/send/initiate/bank",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": .init(userId),
                "sourceAccountId": .init(sourceAccountId),
                "amount": .init(amount),
                "destination": .init(["iban": .init(iban),
                                      "bic": .init(bic)] as [String: KeyAppNetworking.AnyEncodable]),
            ] as [String: KeyAppNetworking.AnyEncodable],
            timestamp: timestamp
        )
    }

    static func getAccountStatement(
        baseURL: String,
        keyPair: KeyPair,
        userId: String,
        accountId: String,
        startDate: Date,
        endDate: Date,
        page: Int,
        timestamp: NSDate = NSDate()
    ) throws -> Self {
        try StrigaEndpoint(
            baseURL: baseURL,
            path: "/striga/api/v1/wallets/get/account/statement",
            method: .post,
            keyPair: keyPair,
            body: [
                "userId": .init(userId),
                "accountId": .init(accountId),
                "startDate": .init(startDate.millisecondsSince1970),
                "endDate": .init(endDate.millisecondsSince1970),
                "page": .init(page),
            ] as [String: KeyAppNetworking.AnyEncodable],
            timestamp: timestamp
        )
    }
}

extension KeyPair {
    func getSignedTimestampMessage(timestamp: NSDate = NSDate()) throws -> String {
        // get timestamp
        let timestamp = "\(Int(timestamp.timeIntervalSince1970) * 1000)"

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
