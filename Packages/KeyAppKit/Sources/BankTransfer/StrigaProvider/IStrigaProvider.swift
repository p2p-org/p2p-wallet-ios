//
//  IStrigaProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 15.05.2023.
//

import Foundation

public protocol IStrigaProvider: AnyObject {
    func getUserDetails(authHeader: StrigaEndpoint.AuthHeader, userId: String) async throws -> UserDetailsResponse
    func createUser(authHeader: StrigaEndpoint.AuthHeader, model: CreateUserRequest) async throws -> CreateUserResponse
    func verifyMobileNumber(authHeader: StrigaEndpoint.AuthHeader, userId: String, verificationCode: String) async throws
}
