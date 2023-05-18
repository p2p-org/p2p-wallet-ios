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
        let tokenBalance: BigUInt?
        // let error: ??

        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<EthereumTokenBalances.Balance.CodingKeys> = try decoder.container(keyedBy: EthereumTokenBalances.Balance.CodingKeys.self)
            self.contractAddress = try container.decode(EthereumAddress.self, forKey: EthereumTokenBalances.Balance.CodingKeys.contractAddress)

            let balance = try container.decodeIfPresent(String.self, forKey: EthereumTokenBalances.Balance.CodingKeys.tokenBalance)
            if let balance {
                let balanceWithoutPrefix = balance.suffix(balance.count - 2)
                self.tokenBalance = BigUInt(balanceWithoutPrefix, radix: 16)
            } else {
                self.tokenBalance = nil
            }
        }
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
    /// Async func for getting balance of given ethereum address
    func getBalance(address: EthereumAddress, block: EthereumQuantityTag) async throws -> EthereumQuantity {
        try await withCheckedThrowingContinuation { continuation in
            self.getBalance(address: address, block: block) { response in
                response.to(continuation: continuation)
            }
        }
    }

    /// Method to get tokens balance for given ethereum address
    func getTokenBalances(address: EthereumAddress, response: @escaping Web3.Web3ResponseCompletion<EthereumTokenBalances>) {
        let req = BasicRPCRequest(id: properties.rpcId, jsonrpc: Web3.jsonrpc, method: "alchemy_getTokenBalances", params: [address, "erc20"])

        properties.provider.send(request: req, response: response)
    }

    /// Async method to get tokens balance for given ethereum address
    func getTokenBalances(address: EthereumAddress) async throws -> EthereumTokenBalances {
        try await withCheckedThrowingContinuation { continuation in
            self.getTokenBalances(address: address) { response in
                response.to(continuation: continuation)
            }
        }
    }

    /// Method to get token metadata
    func getTokenMetadata(address: EthereumAddress, response: @escaping Web3.Web3ResponseCompletion<EthereumTokenMetadata>) {
        let req = BasicRPCRequest(id: properties.rpcId, jsonrpc: Web3.jsonrpc, method: "alchemy_getTokenMetadata", params: [address])

        properties.provider.send(request: req, response: response)
    }

    /// Async method to get token metadata
    func getTokenMetadata(address: EthereumAddress) async throws -> EthereumTokenMetadata {
        try await withCheckedThrowingContinuation { continuation in
            self.getTokenMetadata(address: address) { response in
                response.to(continuation: continuation)
            }
        }
    }
}

private extension Web3Response {
    func to(continuation: CheckedContinuation<Result, Swift.Error>) {
        switch status {
        case let .success(result):
            continuation.resume(returning: result)
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }
}
