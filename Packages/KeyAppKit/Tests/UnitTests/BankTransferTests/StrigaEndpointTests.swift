import XCTest
@testable import BankTransfer
import SolanaSwift
import TweetNacl

class StrigaEndpointTests: XCTestCase {
    
    func testGetSignedTimestampMessage() async throws {
        let keyPair = try await KeyPair(
            phrase: "miracle pizza supply useful steak border same again youth silver access hundred"
                .components(separatedBy: " "),
            network: .mainnetBeta
        )
        let date = NSDate(timeIntervalSince1970: 1685587890.6146898)
        
        let signedTimestampMessage = try keyPair.getSignedTimestampMessage(date: date)
        
        let expectedMessage = "1685587890000:VhqmzP3ub4pQv8WwZG4IUMVeMwDPYXPQDRAIRxSFmMVezD5MWIBRl/UN11mpu0XXYXweaFHV92joLN2c89SEDg=="
        
        XCTAssertEqual(signedTimestampMessage, expectedMessage)
    }
    
    func testVerifyMobileNumber() throws {
        let baseURL = "https://example.com/api/v1/user"
        let keyPair = try KeyPair()
        let userId = "userId"
        let verificationCode = "code"
        
        let endpoint = try StrigaEndpoint.verifyMobileNumber(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId,
            verificationCode: verificationCode
        )
        
        XCTAssertEqual(endpoint.urlString, "https://example.com/api/v1/user/verify-mobile")
        XCTAssertEqual(endpoint.method, .post)
        
        let expectedHeader = [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": try keyPair.getSignedTimestampMessage()
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)
        
        let expectedBody = "{\"userId\":\"userId\",\"verificationCode\":\"code\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }
    
    func testGetUserDetails() throws {
        let baseURL = "https://example.com/api/v1/user"
        let keyPair = try KeyPair()
        let userId = "abdicidjdi"
        
        let endpoint = try StrigaEndpoint.getUserDetails(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId
        )
        
        XCTAssertEqual(endpoint.urlString, "https://example.com/api/v1/user/abdicidjdi")
        XCTAssertEqual(endpoint.method, .get)
        
        let expectedHeader = [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": try keyPair.getSignedTimestampMessage()
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)
        
        XCTAssertNil(endpoint.body)
    }
    
    func testCreateUser() throws {
        let baseURL = "https://example.com/api/v1/user"
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
            occupation: "sth",
            sourceOfFunds: "sth",
            ipAddress: "127.0.0.1",
            placeOfBirth: "South America",
            expectedIncomingTxVolumeYearly: "20000",
            expectedOutgoingTxVolumeYearly: "20000",
            selfPepDeclaration: true,
            purposeOfAccount: "hack"
        )

        let endpoint = try StrigaEndpoint.createUser(
            baseURL: baseURL,
            keyPair: keyPair,
            body: body
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/api/v1/user/create")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": try keyPair.getSignedTimestampMessage()
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody = "{\"address\":{\"addressLine1\":\"Elon str, 1\",\"city\":\"New York\",\"country\":\"United States\",\"postalCode\":\"12345\",\"state\":\"NY\"},\"dateOfBirth\":{\"day\":1,\"month\":12,\"year\":1987},\"email\":\"me@starlink.com\",\"expectedIncomingTxVolumeYearly\":\"20000\",\"expectedOutgoingTxVolumeYearly\":\"20000\",\"firstName\":\"Elon\",\"ipAddress\":\"127.0.0.1\",\"lastName\":\"Musk\",\"mobile\":{\"countryCode\":\"1\",\"number\":\"123443453\"},\"occupation\":\"sth\",\"placeOfBirth\":\"South America\",\"purposeOfAccount\":\"hack\",\"selfPepDeclaration\":true,\"sourceOfFunds\":\"sth\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }
    
    func testResendSMS() throws {
        let baseURL = "https://example.com/api/v1/user"
        let keyPair = try KeyPair()
        let userId = "ijivjiji-jfijdij"

        let endpoint = try StrigaEndpoint.resendSMS(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/api/v1/user/resend-sms")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": try keyPair.getSignedTimestampMessage()
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody = "{\"userId\":\"ijivjiji-jfijdij\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }
    
    func testKYCGetToken() throws {
        let baseURL = "https://example.com/api/v1/user"
        let keyPair = try KeyPair()
        let userId = "ijivjiji-jfijdij"

        let endpoint = try StrigaEndpoint.getKYCToken(
            baseURL: baseURL,
            keyPair: keyPair,
            userId: userId
        )

        XCTAssertEqual(endpoint.urlString, "https://example.com/api/v1/user/kyc/start")
        XCTAssertEqual(endpoint.method, .post)

        let expectedHeader = [
            "Content-Type": "application/json",
            "User-PublicKey": keyPair.publicKey.base58EncodedString,
            "Signed-Message": try keyPair.getSignedTimestampMessage()
        ]
        XCTAssertEqual(endpoint.header, expectedHeader)

        let expectedBody = "{\"userId\":\"ijivjiji-jfijdij\"}"
        XCTAssertEqual(endpoint.body, expectedBody)
    }
}
