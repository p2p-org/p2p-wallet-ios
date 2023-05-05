//
//  File.swift
//  
//
//  Created by Giang Long Tran on 22.03.2023.
//

import Foundation

//public class WormholeMockAPI: WormholeAPI {
//    public func getEthereumBundle(userWallet: String, recipient: String, token: String?, amount: String, slippage: UInt8) async throws -> WormholeBundle {
//        .init(
//            bundleId: "",
//            userWallet: <#T##String#>,
//            recipient: <#T##String#>,
//            resultAmount: <#T##TokenAmount#>,
//            compensationDeclineReason: <#T##CompensationDeclineReason?#>,
//            expiresAt: <#T##Int#>,
//            transactions: <#T##[String]#>,
//            fees: <#T##ClaimFees#>
//        )
//    }
//
//    public func sendEthereumBundle(bundle: WormholeBundle) async throws {
//        try await self.client.invoke(
//            method: "send_ethereum_bundle",
//            params: ["bundle": bundle]
//        )
//    }
//
//    public func simulateEthereumBundle(bundle: WormholeBundle) async throws {
//        try await self.client.invoke(
//            method: "simulate_ethereum_bundle",
//            params: ["bundle": bundle]
//        )
//    }
//
//    public func getEthereumFees(userWallet: String, recipient: String, token: String?, amount: String) async throws -> ClaimFees {
//        try await self.client.call(
//            method: "get_ethereum_fees",
//            params: [
//                "user_wallet": userWallet,
//                "recipient": recipient,
//                "token": token,
//                "amount": amount,
//            ]
//        )
//    }
//
//    public func listEthereumBundles(userWallet: String) async throws -> [WormholeBundleStatus] {
//        try await self.client.call(
//            method: "list_ethereum_bundles",
//            params: [
//                "user_wallet": userWallet,
//            ]
//        )
//    }
//
//    public func getEthereumBundleStatus(bundleID: String) async throws -> WormholeBundleStatus {
//        try await self.client.call(
//            method: "get_ethereum_bundle_status",
//            params: [
//                "bundle_id": bundleID,
//            ]
//        )
//    }
//
//    public func transferFromSolana(
//        userWallet: String,
//        feePayer: String,
//        from: String,
//        recipient: String,
//        mint: String?,
//        amount: String
//    ) async throws -> [String] {
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
//    }
//
//    public func getTransferFees(userWallet: String, recipient: String, mint: String?, amount: String) async throws -> SendFees {
//        try await self.client.call(
//            method: "get_send_fees",
//            params: [
//                "user_wallet": userWallet,
//                "recipient": recipient,
//                "mint": mint,
//                "amount": amount,
//            ]
//        )
//    }
//}
