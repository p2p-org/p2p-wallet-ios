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
