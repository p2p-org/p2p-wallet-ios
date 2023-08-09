import SolanaSwift
import TweetNacl
import XCTest
@testable import BankTransfer

class StrigaEndpointTests: XCTestCase {
    let baseURL = "https://example.com"

    func testGetSignedTimestampMessage() async throws {
        let keyPair = try await KeyPair(
            phrase: "miracle pizza supply useful steak border same again youth silver access hundred"
                .components(separatedBy: " "),
            network: .mainnetBeta
        )
        let date = NSDate(timeIntervalSince1970: 1_685_587_890.6146898)

        let signedTimestampMessage = try keyPair.getSignedTimestampMessage(timestamp: date)

        let expectedMessage =
            "1685587890000:VhqmzP3ub4pQv8WwZG4IUMVeMwDPYXPQDRAIRxSFmMVezD5MWIBRl/UN11mpu0XXYXweaFHV92joLN2c89SEDg=="

        XCTAssertEqual(signedTimestampMessage, expectedMessage)
    }

    func testGetKYC() throws {
        let keyPair = try KeyPair()
        let userId = "userId"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.getKYC(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/user/kyc/userId")
        XCTAssertEqual(endpoint.method, .get)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        XCTAssertNil(endpoint.body)
    }

    func testVerifyMobileNumber() throws {
        let keyPair = try KeyPair()
        let userId = "userId"
        let verificationCode = "code"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.verifyMobileNumber(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            verificationCode: verificationCode,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/user/verify-mobile")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody = "{\"userId\":\"userId\",\"verificationCode\":\"code\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }

    func testGetUserDetails() throws {
        let keyPair = try KeyPair()
        let userId = "abdicidjdi"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.getUserDetails(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/user/abdicidjdi")
        XCTAssertEqual(endpoint.method, .get)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        XCTAssertNil(endpoint.body)
    }

    func testCreateUser() throws {
        let keyPair = try KeyPair()
        let body = StrigaCreateUserRequest(
            firstName: "Elon",
            lastName: "Musk",
            email: "me@starlink.com",
            mobile: .init(
                countryCode: "1",
                number: "123443453"
            ),
            dateOfBirth: .init(year: 1987, month: 12, day: 1),
            address: .init(
                addressLine1: "Elon str, 1",
                addressLine2: nil,
                city: "New York",
                postalCode: "12345",
                state: "NY",
                country: "United States"
            ),
            occupation: .accounting,
            sourceOfFunds: .civilContract,
            ipAddress: "127.0.0.1",
            placeOfBirth: "FRA",
            expectedIncomingTxVolumeYearly: "20000",
            expectedOutgoingTxVolumeYearly: "20000",
            selfPepDeclaration: true,
            purposeOfAccount: "hack"
        )
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.createUser(
            baseURL: baseURL,
            keyPair: keyPair,
            body: body,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/api/v1/user/create")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody =
            "{\"address\":{\"addressLine1\":\"Elon str, 1\",\"city\":\"New York\",\"country\":\"United States\",\"postalCode\":\"12345\",\"state\":\"NY\"},\"dateOfBirth\":{\"day\":1,\"month\":12,\"year\":1987},\"email\":\"me@starlink.com\",\"expectedIncomingTxVolumeYearly\":\"20000\",\"expectedOutgoingTxVolumeYearly\":\"20000\",\"firstName\":\"Elon\",\"ipAddress\":\"127.0.0.1\",\"lastName\":\"Musk\",\"mobile\":{\"countryCode\":\"1\",\"number\":\"123443453\"},\"occupation\":\"ACCOUNTING\",\"placeOfBirth\":\"FRA\",\"purposeOfAccount\":\"hack\",\"selfPepDeclaration\":true,\"sourceOfFunds\":\"CIVIL_CONTRACT\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }

    func testResendSMS() throws {
        let keyPair = try KeyPair()
        let userId = "ijivjiji-jfijdij"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.resendSMS(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/user/resend-sms")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody = "{\"userId\":\"ijivjiji-jfijdij\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }

    func testKYCGetToken() throws {
        let keyPair = try KeyPair()
        let userId = "ijivjiji-jfijdij"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.getKYCToken(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/user/kyc/start")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody = "{\"userId\":\"ijivjiji-jfijdij\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }

    func testGetAllWallets() throws {
        let keyPair = try KeyPair()
        let userId = "ijivjiji-jfijdij"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.getAllWallets(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 2),
            page: 1,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/wallets/get/all")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody = "{\"endDate\":2000,\"page\":1,\"startDate\":0,\"userId\":\"ijivjiji-jfijdij\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }

    func testEnrichAccount() throws {
        let keyPair = try KeyPair()
        let userId = "19085577-4f74-40ad-a86c-0ad28d664170"
        let accountId = "817c19ad473cd1bef869b408858156a2"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.enrichAccount(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            accountId: accountId,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/wallets/account/enrich")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = try [
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
            "Content-Type": "application/json",
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody =
            "{\"accountId\":\"817c19ad473cd1bef869b408858156a2\",\"userId\":\"19085577-4f74-40ad-a86c-0ad28d664170\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }

    func testInitiateOnChainWalletSend() throws {
        let keyPair = try KeyPair()
        let userId = "19085577-4f74-40ad-a86c-0ad28d664170"
        let sourceAccountId = "817c19ad473cd1bef869b408858156a2"
        let whitelistedAddressId = "817c19ad473cd1bef869b408858156a2"
        let amount = "123"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.initiateOnChainWalletSend(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            sourceAccountId: sourceAccountId,
            whitelistedAddressId: whitelistedAddressId,
            amount: amount,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/api/v1/wallets/send/initiate/onchain")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeaders = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeaders)

        let expectedBody =
            "{\"accountCreation\":false,\"amount\":\"123\",\"sourceAccountId\":\"817c19ad473cd1bef869b408858156a2\",\"userId\":\"19085577-4f74-40ad-a86c-0ad28d664170\",\"whitelistedAddressId\":\"817c19ad473cd1bef869b408858156a2\"}"
        XCTAssertEqual(endpoint.body!, expectedBody)
    }

    func testTransactionResendOTPEndpoint() throws {
        let keyPair = try KeyPair()
        let userId = "cecaea44-47f2-439b-99a1-a35fefaf1eb6"
        let challengeId = "f56aaf67-acc1-4397-ae6b-57b553bdc5b0"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.transactionResendOTP(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            challengeId: challengeId,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/wallets/transaction/resend-otp")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody =
            "{\"challengeId\":\"f56aaf67-acc1-4397-ae6b-57b553bdc5b0\",\"userId\":\"cecaea44-47f2-439b-99a1-a35fefaf1eb6\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }

    func testTransactionConfirmOTPEndpoint() throws {
        let keyPair = try KeyPair()
        let userId = "cecaea44-47f2-439b-99a1-a35fefaf1eb6"
        let challengeId = "f56aaf67-acc1-4397-ae6b-57b553bdc5b0"
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.transactionConfirmOTP(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            challengeId: challengeId,
            verificationCode: "123456",
            ip: "ipString",
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/wallets/transaction/confirm")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody =
            "{\"challengeId\":\"f56aaf67-acc1-4397-ae6b-57b553bdc5b0\",\"ip\":\"ipString\",\"userId\":\"cecaea44-47f2-439b-99a1-a35fefaf1eb6\",\"verificationCode\":\"123456\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }

    func testExchangeRatesEndpoint() async throws {
        let keyPair = try KeyPair()
        let timestamp = NSDate()

        let endpoint = try StrigaEndpoint.exchangeRates(
            baseURL: baseURL,
            keyPair: keyPair,
            timestamp: timestamp
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/striga/api/v1/trade/rates")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = try [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": keyPair.getSignedTimestampMessage(timestamp: timestamp),
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)
        XCTAssertEqual(endpoint.body, nil)
    }
}
