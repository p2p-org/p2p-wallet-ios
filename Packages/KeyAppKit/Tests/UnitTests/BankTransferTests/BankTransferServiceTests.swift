//
//  BankTransferServiceTests.swift
//  
//
//  Created by Ivan on 24.05.2023.
//

import Foundation
import XCTest

@testable import BankTransfer

final class BankTransferServiceTests: XCTestCase {
    
    var bankTransferService: BankTransferServiceImpl!
    var strigaProvider: MockStrigaProvider!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        strigaProvider = .init()
        // TODO: - How to mock KeyPair?
//        bankTransferService = .init(strigaProvider: strigaProvider, keyPair: KeyPair())
    }
    
    override func tearDownWithError() throws {
        strigaProvider = nil
        bankTransferService = nil
        
        try super.tearDownWithError()
    }
    
    @MainActor
    func testCreateUserHardcode() async throws {
        
        // when
        _ = try await bankTransferService.createUser(data: .fake())
        
        // then
        let model = strigaProvider.invokedCreateUserParameters!.model
        XCTAssertEqual(model.expectedIncomingTxVolumeYearly, "MORE_THAN_15000_EUR")
        XCTAssertEqual(model.expectedOutgoingTxVolumeYearly, "MORE_THAN_15000_EUR")
        XCTAssertEqual(model.purposeOfAccount, "CRYPTO_PAYMENTS")
    }
}

// MARK: - Mocks

private extension BankTransferRegistrationData where Self == StrigaUserDetailsResponse {
    static func fake() -> StrigaUserDetailsResponse{
        StrigaUserDetailsResponse(
            firstName: "firstName",
            lastName: "lastName",
            email: "email",
            mobile: .init(
                countryCode: "phoneCountryCode",
                number: "phoneNumber"
            ),
            dateOfBirth: .init(year: 2015, month: 10, day: 11),
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
            placeOfBirth: "placeOfBirt"
        )
    }
}
