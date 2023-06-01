////
////  MockStrigaProvider.swift
////  
////
////  Created by Ivan on 24.05.2023.
////
//
//import Foundation
//import BankTransfer
//
//final class MockStrigaProvider: StrigaRemoteProvider {
//    
//    var invokedCreateUser = false
//    var invokedCreateUserCount = 0
//    var invokedCreateUserParameters: (model: StrigaCreateUserRequest, Void)?
//    var invokedCreateUserParametersList = [(model: StrigaCreateUserRequest, Void)]()
//    var stubbedCreateUserResult: Result<StrigaCreateUserResponse, Error>?
//    
//    func createUser(model: StrigaCreateUserRequest) async throws -> StrigaCreateUserResponse {
//        invokedCreateUser = true
//        invokedCreateUserCount += 1
//        invokedCreateUserParameters = (model, ())
//        invokedCreateUserParametersList.append((model, ()))
//        if let stubbedCreateUserResult {
//            switch stubbedCreateUserResult {
//            case let .success(response):
//                return response
//            case let .failure(error):
//                throw error
//            }
//        }
//        throw NSError(domain: "", code: 0)
//    }
//    
//    var invokedGetUserDetails = false
//    var invokedGetUserDetailsCount = 0
//    var invokedGetUserDetailsParameters: (userId: String, Void)?
//    var invokedGetUserDetailsParametersList = [(userId: String, Void)]()
//    var stubbedGetUserDetailsResult: Result<StrigaUserDetailsResponse, Error>?
//    
//    func getUserDetails(userId: String) async throws -> StrigaUserDetailsResponse {
//        invokedGetUserDetails = true
//        invokedGetUserDetailsCount += 1
//        invokedGetUserDetailsParameters = (userId, ())
//        invokedGetUserDetailsParametersList.append((userId, ()))
//        if let stubbedGetUserDetailsResult {
//            switch stubbedGetUserDetailsResult {
//            case let .success(response):
//                return response
//            case let .failure(error):
//                throw error
//            }
//        }
//        throw NSError(domain: "", code: 0)
//    }
//    
//    var invokedGetUserId = false
//    var invokedGetUserIdCount = 0
//    var stubbedGetUserIdResult: Result<String?, Error>?
//    
//    func getUserId() async throws -> String? {
//        invokedGetUserId = true
//        invokedGetUserIdCount += 1
//        if let stubbedGetUserIdResult {
//            switch stubbedGetUserIdResult {
//            case let .success(response):
//                return response
//            case let .failure(error):
//                throw error
//            }
//        }
//        throw NSError(domain: "", code: 0)
//    }
//    
//    var invokedVerifyMobileNumber = false
//    var invokedVerifyMobileNumberCount = 0
//    var invokedVerifyMobileNumberParameters: (userId: String, verificationCode: String)?
//    var invokedVerifyMobileNumberParametersList = [(userId: String, verificationCode: String)]()
//    
//    func verifyMobileNumber(userId: String, verificationCode: String) async throws {
//        invokedVerifyMobileNumber = true
//        invokedVerifyMobileNumberCount += 1
//        invokedVerifyMobileNumberParameters = (userId, verificationCode)
//        invokedVerifyMobileNumberParametersList.append((userId, verificationCode))
//    }
//    
//    var invokedResendSMS = false
//    var invokedResendSMSCount = 0
//    var invokedResendSMSParameters: (userId: String, Void)?
//    var invokedResendSMSParametersList = [(userId: String, Void)]()
//    
//    func resendSMS(userId: String) async throws {
//        invokedResendSMS = true
//        invokedResendSMSCount += 1
//        invokedResendSMSParameters = (userId, ())
//        invokedResendSMSParametersList.append((userId, ()))
//    }
//}
