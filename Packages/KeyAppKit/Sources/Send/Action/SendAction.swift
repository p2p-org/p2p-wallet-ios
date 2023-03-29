import SolanaSwift
import Foundation
import FeeRelayerSwift
import SolanaSwift

public protocol SendActionService {
    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        feeWallet: Wallet?,
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
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        feeWallet: Wallet?,
        ignoreTopUp: Bool,
        memo: String?,
        operationType: StatsInfo.OperationType
    ) async throws -> String {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else { throw SendError.invalidSourceWallet }
        
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
        from wallet: Wallet,
        receiver: String,
        amount: Lamports,
        feeWallet: Wallet?,
        ignoreTopUp: Bool = false,
        memo: String?,
        operationType: StatsInfo.OperationType
    ) async throws -> String {
        let currency = wallet.token.address

        let payingFeeToken = try? getPayingFeeToken(feeWallet: feeWallet)

        var (preparedTransaction, useFeeRelayer) = try await prepareForSendingToSolanaNetworkViaRelayMethod(
            from: wallet,
            receiver: receiver,
            amount: amount.convertToBalance(decimals: wallet.token.decimals),
            payingFeeToken: payingFeeToken,
            memo: memo
        )
        preparedTransaction.transaction.recentBlockhash = try await solanaAPIClient.getRecentBlockhash(commitment: nil)

        if useFeeRelayer {
            let feePayerSignature: String
            
            if ignoreTopUp {
                feePayerSignature = try await relayService.signRelayTransaction(
                    preparedTransaction,
                    config: FeeRelayerConfiguration(
                        operationType: operationType,
                        currency: currency,
                        autoPayback: false
                    )
                )
            } else {
                feePayerSignature = try await relayService.topUpIfNeededAndSignRelayTransactions(
                    preparedTransaction,
                    fee: payingFeeToken,
                    config: FeeRelayerConfiguration(
                        operationType: operationType,
                        currency: currency
                    )
                )
            }
            
            // get feePayerPubkey and user account
            guard let feePayerPubKey = contextManager.currentContext?.feePayerAddress,
                  let account
            else {
                throw SolanaError.unauthorized
            }
            
            // sign transaction by user
            try preparedTransaction.transaction.sign(signers: [account])
            
            // add feePayer's signature
            try preparedTransaction.transaction.addSignature(
                .init(
                    signature: Data(Base58.decode(feePayerSignature)),
                    publicKey: feePayerPubKey
                )
            )
            
            // serialize transaction
            let serializedTransaction = try preparedTransaction.transaction.serialize().base64EncodedString()
            
            // send to solanaBlockchain
            return try await solanaAPIClient.sendTransaction(transaction: serializedTransaction, configs: RequestConfiguration(encoding: "base64")!)
        } else {
            return try await blockchainClient.sendTransaction(preparedTransaction: preparedTransaction)
        }
    }

    private func prepareForSendingToSolanaNetworkViaRelayMethod(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        payingFeeToken: FeeRelayerSwift.TokenAccount?,
        recentBlockhash: String? = nil,
        lamportsPerSignature _: Lamports? = nil,
        minRentExemption: Lamports? = nil,
        memo: String?
    ) async throws -> (preparedTransaction: PreparedTransaction, useFeeRelayer: Bool) {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else { throw SendError.invalidSourceWallet }
        guard let account = account else { throw SolanaError.unauthorized }
        guard let context = contextManager.currentContext else { throw RelayContextManagerError.invalidContext }
        // prepare fee payer
        let feePayer: PublicKey?
        let useFeeRelayer: Bool

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
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
        if wallet.isNativeSOL {
            preparedTransaction = try await blockchainClient.prepareSendingNativeSOL(
                from: account,
                to: receiver,
                amount: amount,
                feePayer: feePayer
            )
        } else {
            preparedTransaction = try await blockchainClient.prepareSendingSPLTokens(
                account: account,
                mintAddress: wallet.token.address,
                decimals: wallet.token.decimals,
                from: sender,
                to: receiver,
                amount: amount,
                feePayer: feePayer,
                transferChecked: useFeeRelayer, // create transferChecked instruction when using fee relayer
                minRentExemption: minRentExemption
            ).preparedTransaction
        }
        
        // add memo
        if let memo {
            preparedTransaction.transaction.instructions.append(
                try MemoProgram.createMemoInstruction(memo: memo)
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

    private func getPayingFeeToken(feeWallet: Wallet?) throws -> FeeRelayerSwift.TokenAccount? {
        if let feeWallet = feeWallet {
            guard
                let addressString = feeWallet.pubkey,
                let address = try? PublicKey(string: addressString),
                let mintAddress = try? PublicKey(string: feeWallet.token.address)
            else {
                throw SendError.invalidPayingFeeWallet
            }
            return .init(address: address, mint: mintAddress)
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
