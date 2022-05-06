//
//  JsonRpcRequestDto.swift
//  p2p_wallet
//
//  Created by Ivan on 29.04.2022.
//

import Foundation

struct JsonRpcRequestDto<T: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let id = UUID().uuidString
    let method: String
    let params: [T]
}
