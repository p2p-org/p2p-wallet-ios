//

import Foundation
import XCTest
import KeyAppNetworking
import SolanaSwift
import TweetNacl
@testable import BankTransfer

final class StrigaRemoteProviderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - GetKYCStatus

    func testGetKYCStatus_SuccessfulResponse_ReturnsStrigaKYC() async throws {
        // Arrange
        let mockData = #"{"userId":"9fd9f525-cb24-4682-8c5a-aa5c2b7e4dde","emailVerified":false,"mobileVerified":false,"status":"NOT_STARTED"}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let kycStatus = try await provider.getKYCStatus(userId: "123")
        
        // Assert
        XCTAssertEqual(kycStatus.mobileVerified, false)
        XCTAssertEqual(kycStatus.status, .notStarted)
    }

    // MARK: - GetUserDetails

    func testGetUserDetails_SuccessfulResponse_ReturnsStrigaUserDetailsResponse() async throws {
        // Arrange
        let mockData = #"{"firstName":"Claudia","lastName":"Tracy Lind","email":"test_1655832993@mailinator.com","documentIssuingCountry":"PS","nationality":"RS","mobile":{"countryCode":"+372","number":"56316716"},"dateOfBirth":{"month":"1","day":"15","year":"2000"},"address":{"addressLine1":"Sepapaja 12","addressLine2":"Hajumaa","city":"Tallinn","state":"Tallinn","country":"EE","postalCode":"11412"},"occupation":"PRECIOUS_GOODS_JEWELRY","sourceOfFunds":"CIVIL_CONTRACT","purposeOfAccount":"CRYPTO_PAYMENTS","selfPepDeclaration":true,"placeOfBirth":"Antoniettamouth","expectedIncomingTxVolumeYearly":"MORE_THAN_15000_EUR","expectedOutgoingTxVolumeYearly":"MORE_THAN_15000_EUR","KYC":{"emailVerified":true,"mobileVerified":true,"status":"REJECTED","details":["UNSATISFACTORY_PHOTOS","SCREENSHOTS","PROBLEMATIC_APPLICANT_DATA"],"rejectionComments":{"userComment":"The full name on the profile is either missing or incorrect.","autoComment":"Please enter your first and last name exactly as they are written in your identity document."}},"userId":"9fd9f525-cb24-4682-8c5a-aa5c2b7e4dde","createdAt":1655832993460}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let userDetails = try await provider.getUserDetails(userId: "123")
        
        // Assert
//        XCTAssertEqual(userDetails.userId, "9fd9f525-cb24-4682-8c5a-aa5c2b7e4dde")
        XCTAssertEqual(userDetails.firstName, "Claudia")
        XCTAssertEqual(userDetails.lastName, "Tracy Lind")
        XCTAssertEqual(userDetails.email, "test_1655832993@mailinator.com")
//        XCTAssertEqual(userDetails.documentIssuingCountry, "PS")
//        XCTAssertEqual(userDetails.nationality, "RS")
        XCTAssertEqual(userDetails.mobile.countryCode, "+372")
        XCTAssertEqual(userDetails.mobile.number, "56316716")
        XCTAssertEqual(userDetails.dateOfBirth?.month, "1")
        XCTAssertEqual(userDetails.dateOfBirth?.day, "15")
        XCTAssertEqual(userDetails.dateOfBirth?.year, "2000")
        XCTAssertEqual(userDetails.address?.addressLine1, "Sepapaja 12")
        XCTAssertEqual(userDetails.address?.addressLine2, "Hajumaa")
        XCTAssertEqual(userDetails.address?.city, "Tallinn")
        XCTAssertEqual(userDetails.address?.state, "Tallinn")
        XCTAssertEqual(userDetails.address?.country, "EE")
        XCTAssertEqual(userDetails.address?.postalCode, "11412")
        XCTAssertEqual(userDetails.occupation, .preciousGoodsJewelry)
        XCTAssertEqual(userDetails.sourceOfFunds, .civilContract)
//        XCTAssertEqual(userDetails.purposeOfAccount, "OTHER")
//        XCTAssertTrue(userDetails.selfPepDeclaration)
        XCTAssertEqual(userDetails.placeOfBirth, "Antoniettamouth")
//        XCTAssertEqual(userDetails.expectedIncomingTxVolumeYearly, "MORE_THAN_15000_EUR")
//        XCTAssertEqual(userDetails.expectedOutgoingTxVolumeYearly, "MORE_THAN_15000_EUR")
//        XCTAssertTrue(userDetails.KYC.emailVerified ?? false)
        XCTAssertTrue(userDetails.KYC.mobileVerified)
        XCTAssertEqual(userDetails.KYC.status, .rejected)
//        XCTAssertEqual(userDetails.KYC.details, ["UNSATISFACTORY_PHOTOS", "SCREENSHOTS", "PROBLEMATIC_APPLICANT_DATA"])
//        XCTAssertEqual(userDetails.KYC?.rejectionComments?.userComment, "The full name on the profile is either missing or incorrect.")
//        XCTAssertEqual(userDetails.KYC?.rejectionComments?.autoComment, "Please enter your first and last name exactly as they are written in your identity document.")
//        XCTAssertEqual(userDetails.createdAt, 1655832993460)
    }

    // MARK: - Create User

    func testCreateUser_SuccessfulResponse_ReturnsCreateUserResponse() async throws {
        // Arrange
        let mockData = #"{"userId":"de13f7b0-c159-4955-a226-42ca2e4f0b76","email":"test_1652858341@mailinator.com","KYC":{"status":"NOT_STARTED"}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let response = try await provider.createUser(model: StrigaCreateUserRequest(
            firstName: "John",
            lastName: "Doe",
            email: "johndoe@example.com",
            mobile: StrigaCreateUserRequest.Mobile(countryCode: "+1", number: "1234567890"),
            dateOfBirth: StrigaCreateUserRequest.DateOfBirth(year: "1990", month: "01", day: "01"),
            address: StrigaCreateUserRequest.Address(
                addressLine1: "123 Main St",
                addressLine2: "Apt 4B",
                city: "New York",
                postalCode: "10001",
                state: "NY",
                country: "US"
            ),
            occupation: .artEntertainment,
            sourceOfFunds: .civilContract,
            ipAddress: "127.0.0.1",
            placeOfBirth: "New York",
            expectedIncomingTxVolumeYearly: "MORE_THAN_50000_USD",
            expectedOutgoingTxVolumeYearly: "MORE_THAN_50000_USD",
            selfPepDeclaration: true,
            purposeOfAccount: "Personal Savings"
        )
)
        
        // Assert
        XCTAssertEqual(response.userId, "de13f7b0-c159-4955-a226-42ca2e4f0b76")
        XCTAssertEqual(response.email, "test_1652858341@mailinator.com")
        XCTAssertEqual(response.KYC.status, .notStarted)
    }

    // MARK: - Verify phone number

    func testVerifyPhoneNumber_SuccessfulResponse_ReturnsAccepted() async throws {
        // Arrange
        let mockData = #"Accepted"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        try await provider.verifyMobileNumber(userId: "123", verificationCode: "123456")
        
        // Assert
        XCTAssertTrue(true)
    }
    
    func testVerifyPhoneNumber_EmptyResponse400_ReturnsInvalidResponse() async throws {
        // Arrange
        let mockData = #"{}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 409)
        
        // Act
        do {
            try await provider.verifyMobileNumber(userId: "123", verificationCode: "123456")
            XCTFail()
        } catch HTTPClientError.invalidResponse(_, _) {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }
    
    func testVerifyPhoneNumber_ErrorDetail409_ReturnsOtpExceededVerification() async throws {
        // Arrange
        let mockData = #"{"status":409,"errorCode":"30003","errorDetails":{"message":"Exceeded verification attempts"}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 409)
        
        // Act
        do {
            try await provider.verifyMobileNumber(userId: "123", verificationCode: "123456")
            XCTFail()
        } catch BankTransferError.otpExceededVerification {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }

    // MARK: - Resend SMS

    func testResendSMS_SuccessfulResponse_ReturnsAccepted() async throws {
        // Arrange
        let mockData = #"Ok"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        try await provider.resendSMS(userId: "123")
        
        // Assert
        XCTAssertTrue(true)
    }
    
    func testResendSMS_EmptyResponse400_ReturnsInvalidResponse() async throws {
        // Arrange
        let mockData = #"{}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 400)
        
        // Act
        do {
            try await provider.resendSMS(userId: "123")
            XCTFail()
        } catch HTTPClientError.invalidResponse(_, _) {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }
    
    func testResendSMS_ErrorDetail409_ReturnsInvalidResponse() async throws {
        // Arrange
        let mockData = #"{"message":"Mobile is already verified","errorCode":"00002","errorDetails":{"message":"Mobile is already verified","errorDetails":"885d9dd3-56d1-416b-a85b-873fcec69071"}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 409)
        
        // Act
        do {
            try await provider.resendSMS(userId: "123")
            XCTFail()
        } catch BankTransferError.mobileAlreadyVerified {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }

    // MARK: - GetKYCToken

    func testGetKYCToken_SuccessfulResponse_ReturnsToken() async throws {
        // Arrange
        let mockData = #"{"provider":"SUMSUB","token":"_act-sbx-cc6a85f3-4315-4d26-b507-3e5ea31ff2f9","userId":"2f1853b2-927a-4aa9-8bb1-3e51fb119ace","verificationLink":"https://in.sumsub.com/idensic/l/#/sbx_Eke06K3fpzlbWuf3"}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let token = try await provider.getKYCToken(userId: "123")
        
        // Assert
        XCTAssertEqual(token, "_act-sbx-cc6a85f3-4315-4d26-b507-3e5ea31ff2f9")
    }
    
    func testGetKYCToken_InvalidFields400_ReturnsInvalidResponse() async throws {
        // Arrange
        let mockData = #"{"status":400,"errorCode":"00002","errorDetails":{"message":"Invalid fields","errorDetails":[{"msg":"Invalid value","param":"mobile.number","location":"body"}]}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 400)
        
        // Act
        do {
            let _ = try await provider.getKYCToken(userId: "123")
            XCTFail()
        } catch HTTPClientError.invalidResponse(_, _) {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }
    
    func testGetKYCToken_UserNotVerified409_ReturnsInvalidResponse() async throws {
        // Arrange
        let mockData = #"{"status":409,"errorCode":"30007","errorDetails":{"message":"User is not verified"}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 409)
        
        // Act
        do {
            let _ = try await provider.getKYCToken(userId: "123")
            XCTFail()
        } catch HTTPClientError.invalidResponse(_, _) {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }

    
    // MARK: - Helper Methods
    
    func getMockProvider(responseString: String, statusCode: Int) throws -> StrigaRemoteProvider {
        let mockURLSession = MockURLSession(responseString: responseString, statusCode: statusCode, error: nil)
        let httpClient = HTTPClient(urlSession: mockURLSession)
        return StrigaRemoteProviderImpl(baseURL: "https://example.com/api", solanaKeyPair: try KeyPair(), httpClient: httpClient)
    }
}
