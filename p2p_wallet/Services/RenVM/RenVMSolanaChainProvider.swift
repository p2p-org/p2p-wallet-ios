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
        // Constants
        let feePayer = try PublicKey(string: try await feeRelayerAPIClient.getFeePayerPubkey())
        
        // variables
        var instructions = instructions
        var signers = signers
        
        // Mint
        if instructions[0].programId == "BTC5yiRuonJKcQvD9j9QwYKPx4MCGbvkWfvHFyBJG6RY",
           instructions[1].programId == "KeccakSecp256k11111111111111111111111111111"
        {
            
            // fix instruction
            var keys = instructions[0].keys
            keys[0] = .writable(publicKey: feePayer, isSigner: true)
            instructions[0] = .init(
                keys: keys,
                programId: instructions[0].programId,
                data: instructions[0].data
            )
            
            // no signer required
            signers = []
        }
        
        // Burn
        else if instructions[0].programId == TokenProgram.id,
                instructions[1].programId == "BTC5yiRuonJKcQvD9j9QwYKPx4MCGbvkWfvHFyBJG6RY"
        {
            let owner = signers[0].publicKey
            // get fee rent
            let rentExemption = try await apiClient.getMinimumBalanceForRentExemption(span: 97)
            
            // prepend first transfer instruction
            instructions.insert(
                SystemProgram.transferInstruction(
                    from: feePayer,
                    to: owner,
                    lamports: rentExemption
                ),
                at: 0
            )
            
            // modify third instructions
            var keys = instructions[2].keys
            keys[0] = .writable(publicKey: keys[0].publicKey, isSigner: true)
            
            instructions[2] = .init(
                keys: keys,
                programId: instructions[2].programId,
                data: instructions[2].data
            )
            
            // compensation instruction
            let exchangeRate = try await feeRelayerAPIClient.feeTokenData(mint: Token.renBTC.address).exchangeRate
            let compensationAmountDouble = (Double(rentExemption) * exchangeRate / pow(Double(10), Double(Token.nativeSolana.decimals-Token.renBTC.decimals)))
            let compensationAmount = UInt64(compensationAmountDouble.rounded(.up))
            let renBTCMint = try PublicKey(string: Token.renBTC.address)
            instructions.append(
                TokenProgram.transferInstruction(
                    source: try PublicKey.associatedTokenAddress(walletAddress: owner, tokenMintAddress: renBTCMint),
                    destination: try PublicKey.associatedTokenAddress(walletAddress: feePayer, tokenMintAddress: renBTCMint),
                    owner: owner,
                    amount: compensationAmount
                )
            )
        }
        
        // TODO: - Burn
        return try await blockchainClient.prepareTransaction(
            instructions: instructions,
            signers: signers,
            feePayer: feePayer,
            feeCalculator: FreeFeeCalculator() // no fee required
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

private class FreeFeeCalculator: FeeCalculator {
    func calculateNetworkFee(transaction: Transaction) throws -> FeeAmount {
        .zero
    }
}
