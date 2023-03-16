//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.03.2023.
//

import Foundation

public protocol WormholeAPI {
    func getEthereumBundle(userWallet: String, recipient: String, token: String?, amount: String, slippage: UInt8?) async throws -> WormholeBundle

    func sendEthereumBundle(bundle: WormholeBundle) async throws

    func simulateEthereumBundle(bundle: WormholeBundle) async throws

    func getEthereumFees(userWallet: String, recipient: String, token: String?, amount: String) async throws -> EthereumFees

    func listEthereumBundles(userWallet: String) async throws -> [WormholeBundleStatus]

    func getEthereumBundleStatus(bundleID: String) async throws -> WormholeBundleStatus
}
