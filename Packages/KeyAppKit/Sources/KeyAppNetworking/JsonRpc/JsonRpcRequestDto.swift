//
//  JsonRpcRequestDto.swift
//  p2p_wallet
//
//  Created by Ivan on 29.04.2022.
//

import Foundation

public struct JsonRpcRequestDto<T: Encodable>: Encodable {
    let jsonrpc: String
    let id: String
    let method: String
    let params: [T]
    
    public init(
        jsonrpc: String = "2.0",
        id: String = UUID().uuidString,
        method: String,
        params: [T]
    ) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.method = method
        self.params = params
    }
}
