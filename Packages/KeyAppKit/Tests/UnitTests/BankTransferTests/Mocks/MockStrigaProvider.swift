//
//  MockStrigaProvider.swift
//  
//
//  Created by Ivan on 24.05.2023.
//

import Foundation
import BankTransfer

final class MockStrigaProvider: IStrigaProvider {
    
    var invokedGetUserDetails = false
    var invokedGetUserDetailsCount = 0
    var invokedGetUserDetailsParameters: (authHeader: StrigaEndpoint.AuthHeader, userId: String, Void)?
    var invokedGetUserDetailsParametersList = [(authHeader: StrigaEndpoint.AuthHeader, userId: String, Void)]()
    var stubbedGetUserDetailsResult: Result<UserDetailsResponse, Error>?
    
    func getUserDetails(authHeader: StrigaEndpoint.AuthHeader, userId: String) async throws -> UserDetailsResponse {
        invokedGetUserDetails = true
        invokedGetUserDetailsCount += 1
        invokedGetUserDetailsParameters = (authHeader, userId, ())
        invokedGetUserDetailsParametersList.append((authHeader, userId, ()))
        if let stubbedGetUserDetailsResult {
            switch stubbedGetUserDetailsResult {
            case let .success(response):
                return response
            case let .failure(error):
                throw error
            }
        }
        throw NSError(domain: "", code: 0)
    }
    
    var invokedCreateUser = false
    var invokedCreateUserCount = 0
    var invokedCreateUserParameters: (authHeader: StrigaEndpoint.AuthHeader, model: BankTransfer.CreateUserRequest, Void)?
    var invokedCreateUserParametersList = [(authHeader: StrigaEndpoint.AuthHeader, model: BankTransfer.CreateUserRequest, Void)]()
    var stubbedCreateUserResult: Result<BankTransfer.CreateUserResponse, Error>?
    
    func createUser(
        authHeader: StrigaEndpoint.AuthHeader,
        model: BankTransfer.CreateUserRequest
    ) async throws -> BankTransfer.CreateUserResponse {
        invokedCreateUser = true
        invokedCreateUserCount += 1
        invokedCreateUserParameters = (authHeader, model, ())
        invokedCreateUserParametersList.append((authHeader, model, ()))
        if let stubbedCreateUserResult {
            switch stubbedCreateUserResult {
            case let .success(response):
                return response
            case let .failure(error):
                throw error
            }
        }
        throw NSError(domain: "", code: 0)
    }
    
    var invokedVerifyMobileNumber = false
    var invokedVerifyMobileNumberCount = 0
    var invokedVerifyMobileNumberParameters: (authHeader: StrigaEndpoint.AuthHeader, userId: String, verificationCode: String)?
    var invokedVerifyMobileNumberParametersList = [(authHeader: StrigaEndpoint.AuthHeader, userId: String, verificationCode: String)]()
    
    func verifyMobileNumber(
        authHeader: StrigaEndpoint.AuthHeader,
        userId: String,
        verificationCode: String
    ) async throws {
        invokedVerifyMobileNumber = true
        invokedVerifyMobileNumberCount += 1
        invokedVerifyMobileNumberParameters = (authHeader, userId, verificationCode)
        invokedVerifyMobileNumberParametersList.append((authHeader, userId, verificationCode))
    }
}
