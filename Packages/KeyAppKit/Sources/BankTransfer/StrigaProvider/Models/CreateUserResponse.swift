//
//  CreateUserResponse.swift
//  
//
//  Created by Ivan on 23.05.2023.
//

import Foundation

public struct CreateUserResponse: Decodable {
    let userId: String
    let email: String
    let KYC: KYC
    
    struct KYC: Decodable {
        let status: String
    }
}
