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
        return try await feeRelayer.topUpAndRelayTransaction(
            context,
            preparedTransaction,
            fee: nil,
            config: .init(
                operationType: .transfer,
                currency: PublicKey.renBTCMint.base58EncodedString
            )
        )
    }
    
    func simulateTransaction(
        preparedTransaction: PreparedTransaction
    ) async throws -> SimulationResult {
        fatalError()
    }
}
