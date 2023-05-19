//  JsonRpcResponseDto.swift
//  p2p_wallet
//
//  Created by Ivan on 29.04.2022.
//

import Foundation

public struct JsonRpcResponseDto<T: Decodable>: Decodable {
    let id: String?
    let result: T?
    let error: JsonRpcError?
    
    public init(
        id: String,
        result: T?,
        error: JsonRpcError? = nil
    ) {
        self.id = id
        self.result = result
        self.error = error
    }
}

public struct JsonRpcError: Decodable, Error {
    public let code: Int
}
