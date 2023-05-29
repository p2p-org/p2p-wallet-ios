//
//  StrigaProviderTests.swift
//  
//
//  Created by Ivan on 24.05.2023.
//

import Foundation
import XCTest

@testable import BankTransfer
@testable import KeyAppNetworking

final class StrigaProviderTests: XCTestCase {
    
    var strigaProvider: StrigaRemoteProviderImpl!
    var httpClient: MockHTTPClient!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        httpClient = .init()
        strigaProvider = .init(httpClient: httpClient)
    }
    
    override func tearDownWithError() throws {
        strigaProvider = nil
        httpClient = nil
        
        try super.tearDownWithError()
    }
    
    @MainActor
    func testGetUserDetailsSuccess() async throws {
        
        // then
        let userId = "123"
        httpClient.stubbedRequestResult = StrigaUserDetailsResponse.fake()
        
        // when
        _ = try await strigaProvider.getUserDetails(authHeader: .init(pubKey: "", signedMessage: ""), userId: userId)
        
        // then
        let endpoint = httpClient.invokedRequestParameters!.endpoint!
        XCTAssertEqual(endpoint.baseURL, "https://payment.keyapp.org/striga/api/v1/user/")
    }
    
    @MainActor
    func testCreateUserEndpointSuccess() async throws {
        
        // then
        httpClient.stubbedRequestResult = CreateUserResponse(userId: "", email: "", KYC: .init(status: ""))
        
        // when
        _ = try await strigaProvider.createUser(authHeader: .init(pubKey: "", signedMessage: ""), model: .fake())
        
        // then
        let endpoint = httpClient.invokedRequestParameters!.endpoint!
        let model = endpoint.body!
        XCTAssertEqual(endpoint.baseURL, "https://payment.keyapp.org/striga/api/v1/user/")
        XCTAssertEqual(model, "{\n  \"address\" : {\n    \"addressLine1\" : \"addressLine1\",\n    \"addressLine2\" : \"addressLine2\",\n    \"city\" : \"city\",\n    \"country\" : \"country\",\n    \"postalCode\" : \"postalCode\",\n    \"state\" : \"state\"\n  },\n  \"dateOfBirth\" : {\n    \"day\" : 24,\n    \"month\" : 5,\n    \"year\" : 2023\n  },\n  \"email\" : \"email\",\n  \"expectedIncomingTxVolumeYearly\" : \"expectedIncomingTxVolumeYearly\",\n  \"expectedOutgoingTxVolumeYearly\" : \"expectedOutgoingTxVolumeYearly\",\n  \"firstName\" : \"firstName\",\n  \"ipAddress\" : \"ipAddress\",\n  \"lastName\" : \"lastName\",\n  \"mobile\" : {\n    \"countryCode\" : \"countryCode\",\n    \"number\" : \"number\"\n  },\n  \"occupation\" : \"occupation\",\n  \"placeOfBirth\" : \"placeOfBirth\",\n  \"purposeOfAccount\" : \"purposeOfAccount\",\n  \"selfPepDeclaration\" : false,\n  \"sourceOfFunds\" : \"sourceOfFunds\"\n}")
    }
    
    @MainActor
    func testVerifyMobileNumberSuccess() async throws {
        
        // then
        httpClient.stubbedRequestResult = ""
        
        // when
        _ = try await strigaProvider.verifyMobileNumber(
            authHeader: .init(pubKey: "", signedMessage: ""),
            userId: "userId",
            verificationCode: "verificationCode"
        )
        
        // then
        let endpoint = httpClient.invokedRequestParameters!.endpoint!
        let model = endpoint.body!
        debugPrint("---model: ", model)
        XCTAssertEqual(endpoint.baseURL, "https://payment.keyapp.org/striga/api/v1/user/")
        XCTAssertEqual(model, "{\n  \"userId\" : \"userId\",\n  \"verificationCode\" : \"verificationCode\"\n}")
    }
}

// MARK: - Fakes

private extension StrigaCreateUserRequest {
    static func fake() -> StrigaCreateUserRequest {
        StrigaCreateUserRequest(
            firstName: "firstName",
            lastName: "lastName",
            email: "email",
            mobile: .init(countryCode: "countryCode", number: "number"),
            dateOfBirth: .init(year: 2023, month: 5, day: 24),
            address: .init(
                addressLine1: "addressLine1",
                addressLine2: "addressLine2",
                city: "city",
                postalCode: "postalCode",
                state: "state",
                country: "country"
            ),
            occupation: "occupation",
            sourceOfFunds: "sourceOfFunds",
            ipAddress: "ipAddress",
            placeOfBirth: "placeOfBirth",
            expectedIncomingTxVolumeYearly: "expectedIncomingTxVolumeYearly",
            expectedOutgoingTxVolumeYearly: "expectedOutgoingTxVolumeYearly",
            selfPepDeclaration: false,
            purposeOfAccount: "purposeOfAccount"
        )
    }
}

private extension StrigaUserDetailsResponse {
    static func fake() -> StrigaUserDetailsResponse {
        StrigaUserDetailsResponse(
            firstName: "firstName",
            lastName: "lastName",
            email: "email",
            mobile: .init(
                countryCode: "countryCode",
                number: "number"
            ),
            dateOfBirth: .init(year: 2023, month: 5, day: 24),
            address: .init(
                addressLine1: "12 Boo str",
                addressLine2: nil,
                city: "Ho Chi Minh city",
                postalCode: "128943",
                state: "Ho Chi Minh",
                country: "Vietnam"
            ),
            occupation: "occupation",
            sourceOfFunds: "sourceOfFunds",
            placeOfBirth: "placeOfBirth"
        )
    }
}
