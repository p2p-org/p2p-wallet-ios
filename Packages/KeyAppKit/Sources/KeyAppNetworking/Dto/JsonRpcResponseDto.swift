//  JsonRpcResponseDto.swift
//  p2p_wallet
//
//  Created by Ivan on 29.04.2022.
//

import Foundation

public struct JsonRpcResponseDto<T: Decodable>: Decodable {
    let id: String?
    let result: T
    
    public init(
        id: String,
        result: T
    ) {
        self.id = id
        self.result = result
    }
}

public struct JsonRpcResponseErrorDto: Decodable {
    public let id: String?
    public let error: JsonRpcError?
}

public struct JsonRpcError: Decodable, Error {
    public let code: Int
}
