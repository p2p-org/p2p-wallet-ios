//
//  StrigaProviderMock.swift
//  
//
//  Created by Ivan on 24.05.2023.
//

import Foundation
import BankTransfer

final class StrigaProviderMock: IStrigaProvider {
    
    var invokedCreateUser = false
    var invokedCreateUserCount = 0
    var invokedCreateUserParameters: (model: BankTransfer.CreateUserRequest, Void)?
    var invokedCreateUserParametersList = [(model: BankTransfer.CreateUserRequest, Void)]()
    var stubbedCreateUserResult: Result<BankTransfer.CreateUserResponse, Error>?
    
    func createUser(model: BankTransfer.CreateUserRequest) async throws -> BankTransfer.CreateUserResponse {
        invokedCreateUser = true
        invokedCreateUserCount += 1
        invokedCreateUserParameters = (model, ())
        invokedCreateUserParametersList.append((model, ()))
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
    var invokedVerifyMobileNumberParameters: (userId: String, verificationCode: String)?
    var invokedVerifyMobileNumberParametersList = [(userId: String, verificationCode: String)]()
    
    func verifyMobileNumber(userId: String, verificationCode: String) async throws {
        invokedVerifyMobileNumber = true
        invokedVerifyMobileNumberCount += 1
        invokedVerifyMobileNumberParameters = (userId, verificationCode)
        invokedVerifyMobileNumberParametersList.append((userId, verificationCode))
    }
}
