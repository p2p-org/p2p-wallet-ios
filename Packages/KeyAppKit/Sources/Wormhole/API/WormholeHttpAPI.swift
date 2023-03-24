//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation
import KeyAppKitCore
import BigInt

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
    
    public func getEthereumFees(userWallet: String, recipient: String, token: String?, amount: String) async throws -> ClaimFees {
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
    
    public func transferFromSolana(
        userWallet: String,
        feePayer: String,
        from: String,
        recipient: String,
        mint: String?,
        amount: String
    ) async throws -> [String] {
        return []
        
//        try await self.client.call(
//            method: "transfer_from_solana",
//            params: [
//                "user_wallet": userWallet,
//                "feePayer": feePayer,
//                "from": from,
//                "recipient": recipient,
//                "mint": mint,
//                "amount": amount,
//            ]
//        )
    }
    
    public func getTransferFees(userWallet: String, recipient: String, mint: String?, amount: String) async throws -> SendFees {
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return try .init(
            arbiter: .init(amount: "1", usdAmount: "1.52", chain: "Solana", contract: nil),
            networkFee: .init(amount: "1", usdAmount: "8.23", chain: "Solana", contract: nil),
            messageAccountRent: .init(amount: "1", usdAmount: "1.23", chain: "Solana", contract: nil),
            bridgeFee: .init(amount: "1", usdAmount: "0.55", chain: "Solana", contract: nil)
        )
        
//        try await self.client.call(
//            method: "get_send_fees",
//            params: [
//                "user_wallet": userWallet,
//                "recipient": recipient,
//                "mint": mint,
//                "amount": amount,
//            ]
//        )
    }
}
