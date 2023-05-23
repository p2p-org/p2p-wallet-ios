//
//  IStrigaProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 15.05.2023.
//

import Foundation

public protocol IStrigaProvider: AnyObject {
    func createUser(model: CreateUserRequest) async throws -> CreateUserResponse
    func verifyMobileNumber(userId: String, verificationCode: String) async throws
}
