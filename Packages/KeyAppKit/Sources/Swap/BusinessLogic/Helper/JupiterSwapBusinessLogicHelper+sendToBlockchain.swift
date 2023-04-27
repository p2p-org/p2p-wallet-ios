import Foundation
import SolanaSwift
import Jupiter
import Task_retrying

extension JupiterSwapBusinessLogicHelper {
    public static func sendToBlockchain(
        account: KeyPair,
        swapTransaction: String?,
        route: Route,
        jupiterClient: JupiterAPI,
        solanaAPIClient: SolanaAPIClient,
        timeOutInSeconds: Int = 60
    ) async throws -> String {
        // retry
        try await Task.retrying(
            where: { $0.isRetryable },
            maxRetryCount: 5,
            retryDelay: 0.5, // 0.5 secs
            timeoutInSeconds: timeOutInSeconds, // wait for 60s if no success then throw .timedOut error
            operation: { numberOfRetried in
                // if there is transaction, send it
                if numberOfRetried == 0, let swapTransaction {
                    return try await _sendToBlockchain(
                        account: account,
                        swapTransaction: swapTransaction,
                        route: route,
                        solanaAPIClient: solanaAPIClient
                    )
                }
                // if not create transaction
                else {
                    // re-create transaction
                    let swapTransaction = try await jupiterClient.swap(
                        route: route,
                        userPublicKey: account.publicKey.base58EncodedString,
                        wrapUnwrapSol: true,
                        feeAccount: nil,
                        computeUnitPriceMicroLamports: nil
                    )

                    // assert swapTransaction
                    guard let swapTransaction else {
                        throw JupiterError.invalidResponse
                    }

                    // retry
                    return try await _sendToBlockchain(
                        account: account,
                        swapTransaction: swapTransaction,
                        route: route,
                        solanaAPIClient: solanaAPIClient
                    )
                }
            }
        ).value
    }
    
    private static func _sendToBlockchain(
        account: KeyPair,
        swapTransaction: String,
        route: Route,
        solanaAPIClient: SolanaAPIClient
    ) async throws -> String {
        // get versioned transaction
        guard let base64Data = Data(base64Encoded: swapTransaction, options: .ignoreUnknownCharacters),
              let versionedTransaction = try? VersionedTransaction.deserialize(data: base64Data)
        else {
            throw JupiterError.invalidResponse
        }

        // send to block chain
        let transactionId = try await _sendToBlockchain(
            account: account,
            versionedTransaction: versionedTransaction,
            solanaAPIClient: solanaAPIClient
        )
        return transactionId
    }
//
    private static func _sendToBlockchain(
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

// MARK: - Helpers

private extension Swift.Error {
    var isRetryable: Bool {
        switch self {
        case let error as APIClientError:
            switch error {
            case let .responseError(response) where
                response.message == "Transaction simulation failed: Blockhash not found" ||
                response.message?.hasSuffix("custom program error: 0x1786") == true:
                return true
            default:
                return false
            }
        case let error as JupiterError:
            switch error {
            case .invalidResponse:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
