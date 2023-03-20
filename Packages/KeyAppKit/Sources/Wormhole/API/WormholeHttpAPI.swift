//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation
import KeyAppKitCore

public class WormholeRPCAPI: WormholeAPI {
    let client: HTTPJSONRPCCLient
    
    public init(endpoint: String, urlSession: URLSession = URLSession.shared) {
        self.client = .init(endpoint: endpoint, urlSession: urlSession)
    }
    
    public func getEthereumBundle(userWallet: String, recipient: String, token: String?, amount: String, slippage: UInt8) async throws -> WormholeBundle {
        /// Internal structure for params
        struct Params: Codable {
            let userWallet: String
            let recipient: String
            let token: String?
            let amount: String
            let slippage: UInt8
            
            enum CodingKeys: String, CodingKey {
                case userWallet = "user_wallet"
                case recipient
                case token
                case amount
                case slippage
            }
        }
        
        // Request
        return try await self.client.call(
            method: "get_ethereum_bundle",
            params: Params(
                userWallet: userWallet,
                recipient: recipient,
                token: token,
                amount: amount,
                slippage: slippage
            )
        )
    }
    
    public func sendEthereumBundle(bundle: WormholeBundle) async throws {
        try await self.client.invoke(
            method: "send_ethereum_bundle",
            params: ["bundle": bundle]
        )
    }
    
    public func simulateEthereumBundle(bundle: WormholeBundle) async throws {
        try await self.client.invoke(
            method: "simulate_ethereum_bundle",
            params: ["bundle": bundle]
        )
    }
    
    public func getEthereumFees(userWallet: String, recipient: String, token: String?, amount: String) async throws -> EthereumFees {
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
    
    public func listEthereumBundles(userWallet: String) async throws -> [WormholeBundleStatus] {
        try await self.client.call(
            method: "list_ethereum_bundles",
            params: [
                "user_wallet": userWallet,
            ]
        )
    }
    
    public func getEthereumBundleStatus(bundleID: String) async throws -> WormholeBundleStatus {
        try await self.client.call(
            method: "get_ethereum_bundle_status",
            params: [
                "bundle_id": bundleID,
            ]
        )
    }
}
