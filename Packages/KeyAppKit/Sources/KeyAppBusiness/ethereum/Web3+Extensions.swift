//
//  File.swift
//
//
//  Created by Giang Long Tran on 03.03.2023.
//

import Foundation
import Web3

struct EthereumTokenBalances: Codable {
    struct Balance: Codable {
        let contractAddress: EthereumAddress
        let tokenBalance: String?
        // let error: ??
    }

    let address: EthereumAddress
    let tokenBalances: [Balance]
    let pageKey: String?
}

struct EthereumTokenMetadata: Codable {
    let name: String?
    let symbol: String?
    let decimals: UInt8?
    let logo: URL?
}

extension Web3.Eth {
    func getTokenBalances(address: EthereumAddress, response: @escaping Web3.Web3ResponseCompletion<EthereumTokenBalances>) {
        let req = BasicRPCRequest(id: properties.rpcId, jsonrpc: Web3.jsonrpc, method: "alchemy_getTokenBalances", params: [address, "erc20"])

        properties.provider.send(request: req, response: response)
    }

    func getTokenMetadata(address: EthereumAddress, response: @escaping Web3.Web3ResponseCompletion<EthereumTokenMetadata>) {
        let req = BasicRPCRequest(id: properties.rpcId, jsonrpc: Web3.jsonrpc, method: "alchemy_getTokenMetadata", params: [address])

        properties.provider.send(request: req, response: response)
    }
}
