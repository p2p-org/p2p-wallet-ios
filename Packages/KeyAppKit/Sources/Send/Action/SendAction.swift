import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import SolanaSwift

public protocol SendActionService {
    func send(
        from wallet: SolanaAccount,
        receiver: String,
        amount: Double,
        feeWallet: SolanaAccount?,
        ignoreTopUp: Bool,
        memo: String?,
        operationType: StatsInfo.OperationType
    ) async throws -> String
}

public class SendActionServiceImpl: SendActionService {
    private let contextManager: RelayContextManager
    private let solanaAPIClient: SolanaAPIClient
    private let blockchainClient: BlockchainClient
    private let account: KeyPair?
    private let relayService: RelayService

    public init(
        contextManager: RelayContextManager,
        solanaAPIClient: SolanaAPIClient,
        blockchainClient: BlockchainClient,
        relayService: RelayService,
        account: KeyPair?
    ) {
        self.contextManager = contextManager
        self.solanaAPIClient = solanaAPIClient
        self.blockchainClient = blockchainClient
        self.relayService = relayService
        self.account = account
    }

    public func send(
        from wallet: SolanaAccount,
        receiver: String,
        amount: Double,
        feeWallet: SolanaAccount?,
        ignoreTopUp: Bool,
        memo: String?,
        operationType: StatsInfo.OperationType
    ) async throws -> String {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        let sender = wallet.address

        // assert payingFeeWallet
        if !ignoreTopUp && feeWallet == nil {
            throw SendError.invalidPayingFeeWallet
        }

        if receiver == sender {
            throw SendError.sendToYourself
        }

        return try await sendToSolanaBCViaRelayMethod(
            from: wallet,
            receiver: receiver,
            amount: amount,
            feeWallet: feeWallet,
            ignoreTopUp: ignoreTopUp,
            memo: memo,
            operationType: operationType
        )
    }

    func sendToSolanaBCViaRelayMethod(
        from wallet: SolanaAccount,
        receiver: String,
        amount: Lamports,
        feeWallet: SolanaAccount?,
        ignoreTopUp: Bool = false,
        memo: String?,
        operationType: StatsInfo.OperationType
    ) async throws -> String {
        // get currency for logging
        let currency = wallet.token.mintAddress

        // get paying fee token
        let payingFeeToken = try? getPayingFeeToken(
            feeWallet: feeWallet,
            minimumTokenAccountBalance: wallet.minRentExemption ?? 2_039_280
        )

        // prepare sending to Solana (returning legacy transaction)
        var (preparedTransaction, useFeeRelayer) = try await prepareForSendingToSolanaNetworkViaRelayMethod(
            from: wallet,
            receiver: receiver,
            amount: amount.convertToBalance(decimals: wallet.token.decimals),
            payingFeeToken: payingFeeToken,
            memo: memo
        )

        // add blockhash
        preparedTransaction.transaction.recentBlockhash = try await solanaAPIClient.getRecentBlockhash(commitment: nil)

        if useFeeRelayer {
            if ignoreTopUp {
                let versionedTransactions = try await relayService.signTransaction(
                    transactions: [
                        VersionedTransaction(
                            message: .legacy(preparedTransaction.transaction.compileMessage())
                        ),
                    ],
                    config: FeeRelayerConfiguration(
                        operationType: operationType,
                        currency: currency,
                        autoPayback: false
                    )
                )

                // assert result
                guard var versionedTransaction = versionedTransactions.first else {
                    throw FeeRelayerError.invalidSignature
                }

                // assert account
                guard let account else {
                    throw SendActionError.unauthorized
                }

                // sign transaction by user
                try versionedTransaction.sign(signers: [account])

                // serialize transaction
                let serializedTransaction = try versionedTransaction.serialize().base64EncodedString()

                // send to solanaBlockchain
                return try await solanaAPIClient.sendTransaction(
                    transaction: serializedTransaction,
                    configs: RequestConfiguration(encoding: "base64")!
                )

            } else {
                // FIXME: - SignRelayTransaction return different transaction, fall back to relay_transaction
                return try await relayService.topUpIfNeededAndRelayTransaction(
                    preparedTransaction,
                    fee: payingFeeToken,
                    config: FeeRelayerConfiguration(
                        operationType: .transfer,
                        currency: currency
                    )
                )
            }
        } else {
            return try await blockchainClient.sendTransaction(preparedTransaction: preparedTransaction)
        }
    }

    private func prepareForSendingToSolanaNetworkViaRelayMethod(
        from wallet: SolanaAccount,
        receiver: String,
        amount: Double,
        payingFeeToken: FeeRelayerSwift.TokenAccount?,
        recentBlockhash: String? = nil,
        lamportsPerSignature _: Lamports? = nil,
        memo: String?
    ) async throws -> (preparedTransaction: PreparedTransaction, useFeeRelayer: Bool) {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        let sender = wallet.address
        guard let account = account else { throw SendActionError.unauthorized }
        guard let context = contextManager.currentContext else { throw RelayContextManagerError.invalidContext }
        // prepare fee payer
        let feePayer: PublicKey?
        let useFeeRelayer: Bool

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use
        // fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
            context,
            payingTokenMint: payingFeeToken?.mint.base58EncodedString
        ) {
            feePayer = nil
            useFeeRelayer = false
        } else {
            feePayer = context.feePayerAddress
            useFeeRelayer = true
        }

        var preparedTransaction: PreparedTransaction
        if wallet.token.isNative {
            preparedTransaction = try await blockchainClient.prepareSendingNativeSOL(
                from: account,
                to: receiver,
                amount: amount,
                feePayer: feePayer
            )
        } else {
            preparedTransaction = try await blockchainClient.prepareSendingSPLTokens(
                account: account,
                mintAddress: wallet.token.mintAddress,
                tokenProgramId: PublicKey(string: wallet.tokenProgramId),
                decimals: wallet.token.decimals,
                from: sender,
                to: receiver,
                amount: amount,
                feePayer: feePayer,
                transferChecked: useFeeRelayer, // create transferChecked instruction when using fee relayer
                lamportsPerSignature: context.lamportsPerSignature,
                minRentExemption: wallet.minRentExemption ?? 2_039_280
            ).preparedTransaction
        }

        // add memo
        if let memo {
            try preparedTransaction.transaction.instructions.append(
                MemoProgram.createMemoInstruction(memo: memo)
            )
        }

        // send transaction
        preparedTransaction.transaction.recentBlockhash = recentBlockhash
        return (preparedTransaction: preparedTransaction, useFeeRelayer: useFeeRelayer)
    }

    private func isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
        _ context: RelayContext,
        payingTokenMint: String?
    ) -> Bool {
        let expectedTransactionFee = context.lamportsPerSignature * 2
        return payingTokenMint == PublicKey.wrappedSOLMint.base58EncodedString &&
            context.usageStatus.isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
    }

    private func getPayingFeeToken(
        feeWallet: SolanaAccount?,
        minimumTokenAccountBalance: UInt64
    ) throws -> FeeRelayerSwift.TokenAccount? {
        if let feeWallet = feeWallet {
            let addressString = feeWallet.address
            guard let address = try? PublicKey(string: addressString),
                  let mintAddress = try? PublicKey(string: feeWallet.token.mintAddress)
            else {
                throw SendError.invalidPayingFeeWallet
            }
            return .init(
                address: address,
                mint: mintAddress,
                minimumTokenAccountBalance: minimumTokenAccountBalance
            )
        }
        return nil
    }
}

public enum SendError: String, Swift.Error, LocalizedError {
    case invalidSourceWallet = "Source wallet is not valid"
    case sendToYourself = "You can not send tokens to yourself"
    case invalidPayingFeeWallet = "Paying fee wallet is not valid"

    public var errorDescription: String? {
        // swiftlint:disable swiftgen_strings
        NSLocalizedString(rawValue, comment: "")
        // swiftlint:enable swiftgen_strings
    }
}
