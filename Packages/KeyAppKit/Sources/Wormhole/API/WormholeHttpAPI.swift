//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import BigInt
import Foundation
import KeyAppKitCore

public class WormholeRPCAPI: WormholeAPI {
    let client: HTTPJSONRPCCLient

    public init(endpoint: String, urlSession: URLSession = URLSession.shared) {
        client = .init(endpoint: endpoint, urlSession: urlSession)
    }

    public func getEthereumBundle(
        userWallet: String,
        recipient: String,
        token: String?,
        amount: String,
        slippage: UInt8
    ) async throws -> WormholeBundle {
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
        return try await client.call(
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
        try await client.invoke(
            method: "send_ethereum_bundle",
            params: ["bundle": bundle]
        )
    }

    public func simulateEthereumBundle(bundle: WormholeBundle) async throws {
        try await client.invoke(
            method: "simulate_ethereum_bundle",
            params: ["bundle": bundle]
        )
    }

    public func getEthereumFees(
        userWallet: String,
        recipient: String,
        token: String?,
        amount: String
    ) async throws -> ClaimFees {
        try await client.call(
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
        try await client.call(
            method: "list_ethereum_bundles",
            params: [
                "user_wallet": userWallet,
            ]
        )
    }

    public func getEthereumBundleStatus(bundleID: String) async throws -> WormholeBundleStatus {
        try await client.call(
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
    ) async throws -> SendTransaction {
        /// Internal structure for params
        struct Params: Codable {
            let userWallet: String
            let feePayer: String
            let from: String
            let recipient: String
            let mint: String?
            let amount: String

            enum CodingKeys: String, CodingKey {
                case userWallet
                case feePayer
                case from
                case recipient
                case mint
                case amount
            }
        }

        return try await client.call(
            method: "transfer_from_solana",
            params: Params(
                userWallet: userWallet,
                feePayer: feePayer,
                from: from,
                recipient: recipient,
                mint: mint,
                amount: amount
            )
        )
    }

    public func getTransferFees(
        userWallet: String,
        recipient: String,
        mint: String?,
        amount: String
    ) async throws -> SendFees {
        try await client.call(
            method: "get_solana_fees",
            params: [
                "user_wallet": userWallet,
                "recipient": recipient,
                "mint": mint,
                "amount": amount,
            ]
        )
    }

    public func listSolanaStatuses(userWallet: String) async throws -> [WormholeSendStatus] {
        try await client.call(
            method: "list_solana_statuses",
            params: ["user_wallet": userWallet]
        )
    }

    public func getSolanaTransferStatus(message: String) async throws -> WormholeSendStatus? {
        try await client.call(
            method: "get_solana_transfer_status",
            params: [message: message]
        )
    }
}
