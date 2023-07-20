//
//  JsonRpcResponseDto.swift
//  p2p_wallet
//
//  Created by Ivan on 29.04.2022.
//

import Foundation

struct JsonRpcResponseDto<T: Decodable>: Decodable {
    let id: String
    let result: T
}

struct JsonRpcResponseErrorDto: Decodable {
    let id: String
    let error: JsonRpcError
}

struct JsonRpcError: Decodable, Error {
    let code: Int
}
