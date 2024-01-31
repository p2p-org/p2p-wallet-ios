import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import SendService
import SolanaSwift

extension SendActionServiceImpl {
    func sendViaSendService(
        wallet: SolanaAccount,
        amount: UInt64,
        isSendingMaxAmount: Bool,
        receiver: String,
        context: RelayContext,
        feeWallet: SolanaAccount?
    ) async throws -> String {
        guard let account else {
            throw SendError.invalidUserAccount
        }

        // ignore mint if token is native
        let mintAddress = wallet.isNative ? nil : wallet.mintAddress

        // fix amount
        var amount = amount
        if isSendingMaxAmount {
            amount = .max
        }

        let response = try await sendService.transfer(
            userWallet: wallet.address,
            mint: mintAddress,
            amount: amount,
            recipient: receiver,
            transferMode: .exactOut,
            networkFeePayer: getNetworkFeePayer(
                context: context,
                wallet: wallet,
                feeWallet: feeWallet
            ),
            taRentPayer: getTokenAccountFeePayer(
                wallet: wallet,
                feeWallet: feeWallet
            )
        )

        return try await sendToBlockchain(
            account: account,
            transaction: response.transaction
        )
    }

    // MARK: - Helpers

    private func getNetworkFeePayer(
        context: RelayContext,
        wallet: SolanaAccount,
        feeWallet: SolanaAccount?
    ) -> SendServiceTransferFeePayer {
        if context.usageStatus.isFreeTransactionFeeAvailable(
            transactionFee: 2 * context.lamportsPerSignature
        ) {
            return .service
        } else if let feeWallet {
            if feeWallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
                return .userSOL
            } else if feeWallet.mintAddress == wallet.mintAddress {
                return .userSameToken
            } else {
                return .other(pubkey: feeWallet.mintAddress)
            }
        } else {
            return .userSOL
        }
    }

    private func getTokenAccountFeePayer(
        wallet: SolanaAccount,
        feeWallet: SolanaAccount?
    ) -> SendServiceTransferFeePayer {
        if let feeWallet {
            if feeWallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
                return .userSOL
            } else if feeWallet.mintAddress == wallet.mintAddress {
                return .userSameToken
            } else {
                return .other(pubkey: feeWallet.mintAddress)
            }
        } else {
            return .userSOL
        }
    }

    private func sendToBlockchain(
        account: KeyPair,
        transaction: String
    ) async throws -> String {
        // get versioned transaction
        guard let base64Data = Data(base64Encoded: transaction, options: .ignoreUnknownCharacters),
              let versionedTransaction = try? VersionedTransaction.deserialize(data: base64Data)
        else {
            throw SendError.invalidTransaction
        }

        // send to block chain
        let transactionId = try await sendToBlockchain(
            account: account,
            versionedTransaction: versionedTransaction,
            solanaAPIClient: solanaAPIClient
        )
        return transactionId
    }

    private func sendToBlockchain(
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
            transaction: serializedTransaction,
            configs: RequestConfiguration(encoding: "base64")!
        )
    }
}
