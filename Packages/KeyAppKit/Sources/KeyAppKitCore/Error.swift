//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation

public enum ServiceError: Error {
    case authorizationError
}

public enum CodingError: Error {
    case invalidValue
}

public enum ConvertError: Error {
    case invalidPriceForToken(expected: String, actual: String)
    case enormousValue
}

//public protocol KeyAppError: Error, Codable {}

//public struct KeyAppErrorBridge: KeyAppError {
//    public static func == (lhs: KeyAppErrorBridge, rhs: KeyAppErrorBridge) -> Bool {
//        lhs.errorCode == rhs.errorCode
//    }
//
//    public var errorCode: Int
//    public var domain: String
//    public var localizedDescription: String
//    public var userInfo: [String: Any]
//
//    init(error: Error) {
//        let objCError = error as NSError
//
//        errorCode = objCError.code
//        domain = objCError.domain
//        userInfo = objCError.userInfo
//        localizedDescription = objCError.localizedDescription
//    }
//}
