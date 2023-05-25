//
//  UserDetailsResponse.swift
//  
//
//  Created by Ivan on 25.05.2023.
//

import Foundation

public struct UserDetailsResponse: Decodable {
    let firstName: String
    let lastName: String
    let email: String
    let mobile: Mobile
    let dateOfBirth: DateOfBirth?
    let occupation: String?
    let sourceOfFunds: String?
    let ipAddress: String?
    let placeOfBirth: String?
    let expectedIncomingTxVolumeYearly: String?
    let expectedOutgoingTxVolumeYearly: String?
    let selfPepDeclaration: Bool?
    let purposeOfAccount: String?
    
    struct Mobile: Decodable {
        let countryCode: String
        let number: String
    }
    
    struct DateOfBirth: Decodable {
        let year: Int?
        let month: Int?
        let day: Int?
    }
}
