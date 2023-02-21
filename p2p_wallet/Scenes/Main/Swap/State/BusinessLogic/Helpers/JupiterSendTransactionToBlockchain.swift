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
        account: Account,
        versionedTransaction: VersionedTransaction,
        solanaAPIClient: SolanaAPIClient
    ) async throws -> String {

        let blockHash = try await solanaAPIClient.getRecentBlockhash()
        var versionedTransaction = versionedTransaction
        versionedTransaction.setRecentBlockHash(blockHash)
        try versionedTransaction.sign(signers: [account])

        let serializedTransaction = try versionedTransaction.serialize().base64EncodedString()

        return try await solanaAPIClient.sendTransaction(
            transaction: serializedTransaction ?? "",
            configs: RequestConfiguration(encoding: "base64")!
        )
    }
}
