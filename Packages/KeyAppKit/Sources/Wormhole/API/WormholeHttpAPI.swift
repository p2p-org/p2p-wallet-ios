//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation
import KeyAppKitCore

class WormholeRPCAPI: WormholeAPI {
    let client: HTTPJSONRPCCLient
    
    init(endpoint: String, urlSession: URLSession = URLSession.shared) {
        self.client = .init(endpoint: endpoint, urlSession: urlSession)
    }
    
    func getEthereumBundle(userWallet: String, recipient: String, token: String?, amount: String, slippage: UInt8) async throws -> WormholeBundle {
        try await self.client.call(
            method: "get_ethereum_bundle",
            params: [
                "user_wallet": userWallet,
                "recipient": recipient,
                "token": token,
                "amount": amount,
                "slippage": try String(slippage),
            ]
        )
    }
    
    func sendEthereumBundle(bundle: WormholeBundle) async throws {
        try await self.client.invoke(
            method: "send_ethereum_bundle",
            params: ["bundle": bundle]
        )
    }
    
    func getEthereumFees(userWallet: String, recipient: String, token: String?, amount: String) async throws -> EthereumFees {
        try await self.client.call(
            method: "get_ethereum_fees",
            params: [
                "user_wallet": userWallet,
                "recipient": recipient,
                "token": token,
                "amount": amount,
            ]
        )
    }
}
