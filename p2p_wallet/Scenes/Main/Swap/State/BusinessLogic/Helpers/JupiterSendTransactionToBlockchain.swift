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
