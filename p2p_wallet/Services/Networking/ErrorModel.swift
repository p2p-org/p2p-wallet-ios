//
//  ErrorModel.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

enum ErrorModel: Error, LocalizedError {
    case decode
    case invalidURL
    case noResponse
    case unauthorized
    case unexpectedStatusCode
    case unknown
    case api(model: ApiErrorModel)

    var errorDescription: String? {
        switch self {
        case let .api(model):
            return model.message
        case .decode:
            return "Decode error"
        case .unauthorized:
            return "Session expired"
        default:
            return "Unknown error"
        }
    }
}

struct ApiErrorModel: Decodable {
    let code: Int
    let message: String
}
