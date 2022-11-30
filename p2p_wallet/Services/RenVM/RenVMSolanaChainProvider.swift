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
        guard instructions.count == 2 else {
            throw RenVMError("Invalid instructions")
        }
        
        // Mint
        if instructions[0].programId == "BTC5yiRuonJKcQvD9j9QwYKPx4MCGbvkWfvHFyBJG6RY",
           instructions[1].programId == "KeccakSecp256k11111111111111111111111111111"
        {
            let feePayer = try PublicKey(string: try await feeRelayerAPIClient.getFeePayerPubkey())
            var instructions = instructions
            
            // fix instruction
            var keys = instructions[0].keys
            keys[0] = .writable(publicKey: feePayer, isSigner: true)
            instructions[0] = .init(
                keys: keys,
                programId: instructions[0].programId,
                data: instructions[0].data
            )
            
            return try await blockchainClient.prepareTransaction(
                instructions: instructions,
                signers: [],
                feePayer: feePayer,
                feeCalculator: FreeFeeCalculator() // no fee required
            )
        }
        
        // Burn
        else if instructions[0].programId == TokenProgram.id,
                instructions[1].programId == "BTC5yiRuonJKcQvD9j9QwYKPx4MCGbvkWfvHFyBJG6RY"
        {
            // prepare transaction
            return try await blockchainClient.prepareTransaction(
                instructions: instructions,
                signers: signers,
                feePayer: feePayer, // owner pay for himself after swaping
                feeCalculator: feeCalculator
            )
        }
        
        throw RenVMError("Unsupported transaction")
    }
    
    func sendTransaction(
        preparedTransaction: PreparedTransaction
    ) async throws -> String {
        guard preparedTransaction.transaction.instructions.count == 2 else {
            throw RenVMError("Invalid instructions")
        }
        
        // Mint
        if preparedTransaction.transaction.instructions[0].programId == "BTC5yiRuonJKcQvD9j9QwYKPx4MCGbvkWfvHFyBJG6RY",
           preparedTransaction.transaction.instructions[1].programId == "KeccakSecp256k11111111111111111111111111111"
        {
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
        
        // Burn
        else if preparedTransaction.transaction.instructions[0].programId == TokenProgram.id,
                preparedTransaction.transaction.instructions[1].programId == "BTC5yiRuonJKcQvD9j9QwYKPx4MCGbvkWfvHFyBJG6RY"
        {
            do {
                return try await blockchainClient.sendTransaction(preparedTransaction: preparedTransaction)
            } catch SolanaError.invalidResponse(let response) where response.data?.logs != nil {
                print(response)
                let logs = response.data!.logs!
                
                // previous transaction has not been confirmed
                if let burnCheckIndex = logs.firstIndex(of: "Program log: Instruction: BurnChecked"),
                   let burnCheckErrorIndex = logs.firstIndex(of: "Program log: Error: insufficient funds"),
                   burnCheckErrorIndex == burnCheckIndex + 1
                {
                    try await Task.sleep(nanoseconds: 3_000_000) // skip for 3s
                    return try await sendTransaction(preparedTransaction: preparedTransaction) // retry
                }
                // re throw other error
                throw SolanaError.invalidResponse(response)
            } catch APIClientError.responseError(let response) where response.message == "Transaction simulation failed: Attempt to debit an account but found no record of a prior credit." {
                try await Task.sleep(nanoseconds: 3_000_000) // skip for 3s
                return try await sendTransaction(preparedTransaction: preparedTransaction)
            } catch {
                print(error)
                throw error
            }
        }
        
        throw RenVMError("Unsupported transaction")
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

private class FreeFeeCalculator: FeeCalculator {
    func calculateNetworkFee(transaction: Transaction) throws -> FeeAmount {
        .zero
    }
}
