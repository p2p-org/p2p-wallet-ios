//
//  File.swift
//  
//
//  Created by Giang Long Tran on 03.03.2023.
//

import Foundation
import Web3

public struct EthereumTokenBalances: Codable {
    public struct Balance: Codable {
        let contractAddress: EthereumAddress
        let tokenBalance: String?
        // let error: ??
    }
    
    let address: EthereumAddress
    let tokenBalances: [Balance]
    let pageKey: String?
}

extension Web3.Eth {
    public func getTokenBalances(address: EthereumAddress, response: @escaping Web3.Web3ResponseCompletion<EthereumTokenBalances>) {
        let req = BasicRPCRequest(id: properties.rpcId, jsonrpc: Web3.jsonrpc, method: "alchemy_getTokenBalances", params: [address ,"erc20"])
        
        properties.provider.send(request: req, response: response)
    }
}
