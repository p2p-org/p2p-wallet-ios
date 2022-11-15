//
//  RenVMSolanaChainProvider.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2022.
//

import Foundation
import RenVMSwift
import Resolver
import SolanaSwift
import FeeRelayerSwift

class RenVMSolanaChainProvider: ChainProvider {
    @Injected private var accountStorage: SolanaAccountStorage
    @Injected private var rpcClient: RenVMRpcClientType
    @Injected private var apiClient: SolanaAPIClient

    /// Get authorized account from chain
    func getAccount() async throws -> (publicKey: Data, secret: Data) {
        guard let account = accountStorage.account else {
            throw SolanaError.unauthorized
        }
        return (publicKey: account.publicKey.data, secret: account.secretKey)
    }

    /// Load chain
    func load() async throws -> RenVMChainType {
        try await SolanaChain.load(
            client: rpcClient,
            apiClient: apiClient,
            blockchainClient: RenVMFeeRelayerSolanaBlockchainClient()
        )
    }
}

private class RenVMFeeRelayerSolanaBlockchainClient: SolanaBlockchainClient {
    @Injected private var blockchainClient: SolanaBlockchainClient
    @Injected private var feeRelayerAPIClient: FeeRelayerAPIClient
    @Injected private var feeRelayerContextManager: FeeRelayerContextManager
    @Injected private var feeRelayer: FeeRelayer
    
    var apiClient: SolanaAPIClient {
        get { blockchainClient.apiClient }
        set { blockchainClient.apiClient = newValue }
    }
    
    func prepareTransaction(
        instructions: [SolanaSwift.TransactionInstruction],
        signers: [SolanaSwift.Account],
        feePayer: SolanaSwift.PublicKey,
        feeCalculator: SolanaSwift.FeeCalculator?
    ) async throws -> SolanaSwift.PreparedTransaction {
        let feePayer = try await feeRelayerAPIClient.getFeePayerPubkey()
        
        class FreeFeeCalculator: FeeCalculator {
            func calculateNetworkFee(transaction: Transaction) throws -> FeeAmount {
                .zero
            }
        }
        
        var instructions = instructions
        
        // mint
        if instructions.count == 2,
           instructions[0].programId == "BTC5yiRuonJKcQvD9j9QwYKPx4MCGbvkWfvHFyBJG6RY",
           instructions[1].programId == "KeccakSecp256k11111111111111111111111111111"
        {
            // fix first transaction
            var keys = instructions[0].keys
            keys[0] = .writable(publicKey: try PublicKey(string: feePayer), isSigner: true)
            instructions[0] = .init(
                keys: keys,
                programId: instructions[0].programId,
                data: instructions[0].data
            )
        }
        
        // TODO: - Burn
        return try await blockchainClient.prepareTransaction(
            instructions: instructions,
            signers: [],
            feePayer: try PublicKey(string: feePayer),
            feeCalculator: FreeFeeCalculator()
        )
    }
    
    func sendTransaction(
        preparedTransaction: PreparedTransaction
    ) async throws -> String {
        let context = try await feeRelayerContextManager.getCurrentContext()
        do {
            return try await feeRelayer.topUpAndRelayTransaction(
                context,
                preparedTransaction,
                fee: nil,
                config: .init(
                    operationType: .transfer,
                    currency: PublicKey.renBTCMint.base58EncodedString
                )
            )
        } catch SolanaError.invalidResponse(let response) {
            // FIXME: - temporarily fix by converting HTTPClientError to SolanaError
            if response.data?.logs?.contains(where: \.isAlreadyInUseLog) == true {
                throw RenVMError("Already in use")
            }
            throw SolanaError.invalidResponse(response)
        }
    }
    
    func simulateTransaction(
        preparedTransaction: PreparedTransaction
    ) async throws -> SimulationResult {
        fatalError()
    }
}

private extension String {
    var isAlreadyInUseLog: Bool {
        contains("Allocate: account Address { address: ") &&
            contains("} already in use")
    }
}
