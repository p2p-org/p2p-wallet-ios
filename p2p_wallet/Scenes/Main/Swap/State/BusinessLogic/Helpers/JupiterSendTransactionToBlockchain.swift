//
//  JupiterSendTransactionToBlockchain.swift
//  p2p_wallet
//
//  Created by Ivan on 21.02.2023.
//

import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func sendToBlockchain(
        account: KeyPair,
        swapTransaction: String,
        route: Route,
        services: JupiterSwapServices
    ) async throws -> String {
        // get versioned transaction
        guard let base64Data = Data(base64Encoded: swapTransaction, options: .ignoreUnknownCharacters),
              let versionedTransaction = try? VersionedTransaction.deserialize(data: base64Data)
        else {
            throw JupiterError.invalidResponse
        }

        // send to block chain
        do {
            let transactionId = try await sendToBlockchain(
                account: account,
                versionedTransaction: versionedTransaction,
                solanaAPIClient: services.solanaAPIClient
            )
            return transactionId
        }
        
        // catch BlockhashNotFound error
        catch let APIClientError.responseError(response) where
                response.message == "Transaction simulation failed: Blockhash not found" ||
                response.message?.hasSuffix("custom program error: 0x1786")
        {

            // re-create transaction
            let swapTransaction = try await services.jupiterClient.swap(
                route: route,
                userPublicKey: account.publicKey.base58EncodedString,
                wrapUnwrapSol: true,
                feeAccount: nil,
                computeUnitPriceMicroLamports: nil
            )
            
            // get versioned transaction
            guard let swapTransaction,
                  let base64Data = Data(base64Encoded: swapTransaction, options: .ignoreUnknownCharacters),
                  let versionedTransaction = try? VersionedTransaction.deserialize(data: base64Data)
            else {
                throw JupiterError.invalidResponse
            }
            
            // resend the transaction
            let transactionId = try await sendToBlockchain(
                account: account,
                versionedTransaction: versionedTransaction,
                solanaAPIClient: services.solanaAPIClient
            )
            return transactionId
        }
    }
    
    private static func sendToBlockchain(
        account: KeyPair,
        versionedTransaction: VersionedTransaction,
        solanaAPIClient: SolanaAPIClient
    ) async throws -> String {
        // get versioned transaction
        var versionedTransaction = versionedTransaction
        
        // get blockhash if needed (don't need any more)
//        if versionedTransaction.message.value.recentBlockhash == nil {
//            let blockHash = try await solanaAPIClient.getRecentBlockhash()
//            versionedTransaction.setRecentBlockHash(blockHash)
//        }
        
        // sign transaction
        try versionedTransaction.sign(signers: [account])

        // serialize transaction
        let serializedTransaction = try versionedTransaction.serialize().base64EncodedString()

        // send to blockchain
        return try await solanaAPIClient.sendTransaction(
            transaction: serializedTransaction ,
            configs: RequestConfiguration(encoding: "base64")!
        )
    }
}
