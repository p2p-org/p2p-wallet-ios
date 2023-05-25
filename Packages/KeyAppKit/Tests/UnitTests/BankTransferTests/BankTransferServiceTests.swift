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
    
    var bankTransferService: StrigaBankTransferService!
    var strigaProvider: StrigaProviderMock!
    
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

private extension RegistrationData {
    static func fake() -> RegistrationData{
        RegistrationData(
            firstName: "firstName",
            lastName: "lastName",
            email: "email",
            phoneCountryCode: "phoneCountryCode",
            phoneNumber: "phoneNumber",
            dateOfBirth: Date(),
            placeOfBirth: "placeOfBirth",
            occupation: "occupation",
            placeOfLive: "placeOfLive"
        )
    }
}
