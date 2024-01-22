import FeeRelayerSwift
import KeyAppKitCore
import OrcaSwapSwift
import SolanaSwift

public protocol SendFeeCalculator: AnyObject {
    func getFees(
        from token: SolanaAccount,
        recipient: Recipient,
        recipientAdditionalInfo: SendInputState.RecipientAdditionalInfo,
//        payingTokenMint: String?,
        lamportsPerSignature: UInt64,
        limit: SendServiceLimitResponse
    ) async throws -> FeeAmount?

    func calculateFeeInPayingToken(
        orcaSwap: OrcaSwapType,
        feeInSOL: FeeAmount,
        payingFeeTokenMint: PublicKey
    ) async throws -> FeeAmount?
}

public class SendFeeCalculatorImpl: SendFeeCalculator {
    public init() {}

    // MARK: - Fees calculator

    public func getFees(
        from token: SolanaAccount,
        recipient: Recipient,
        recipientAdditionalInfo: SendInputState.RecipientAdditionalInfo,
//        payingTokenMint _: String?,
        lamportsPerSignature: UInt64,
        limit: SendServiceLimitResponse
    ) async throws -> FeeAmount? {
        var transactionFee: UInt64 = 0

        // owner's signature
        transactionFee += lamportsPerSignature

        // feePayer's signature
        transactionFee += lamportsPerSignature

        var isAssociatedTokenUnregister = false

        if token.isNative {
            // User transfer native SOL
            isAssociatedTokenUnregister = false
        } else {
            switch recipient.category {
            case let .solanaTokenAddress(walletAddress, _):
                let associatedAccount = try PublicKey.associatedTokenAddress(
                    walletAddress: walletAddress,
                    tokenMintAddress: PublicKey(string: token.mintAddress),
                    tokenProgramId: PublicKey(string: token.tokenProgramId)
                )

                isAssociatedTokenUnregister = !recipientAdditionalInfo.splAccounts
                    .contains(where: { $0.pubkey == associatedAccount.base58EncodedString })
            case .solanaAddress, .username:
                let associatedAccount = try PublicKey.associatedTokenAddress(
                    walletAddress: PublicKey(string: recipient.address),
                    tokenMintAddress: PublicKey(string: token.mintAddress),
                    tokenProgramId: PublicKey(string: token.tokenProgramId)
                )

                isAssociatedTokenUnregister = !recipientAdditionalInfo.splAccounts
                    .contains(where: { $0.pubkey == associatedAccount.base58EncodedString })
            default:
                break
            }
        }

//        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't
//        /use
//        // fee relayer)
//        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(context, payingTokenMint: payingTokenMint) {
//            // subtract the fee payer signature cost
//            transactionFee -= context.lamportsPerSignature
//        }

        var expectedFee = FeeAmount(
            transaction: transactionFee,
            accountBalances: isAssociatedTokenUnregister ? token.minRentExemption ?? 0 : 0
        )

        // is Top up free
        if limit.networkFee.isAvailable(
            forAmount: expectedFee.transaction
        ) {
            expectedFee.transaction = 0
        }

        return expectedFee
    }

    public func calculateFeeInPayingToken(
        orcaSwap: OrcaSwapType,
        feeInSOL: FeeAmount,
        payingFeeTokenMint: PublicKey
    ) async throws -> FeeAmount? {
        // If token is sol, no conversion needed
        if payingFeeTokenMint == PublicKey.wrappedSOLMint {
            return feeInSOL
        }

        // If token is not sol, we need to get poolsPairs for trading token to SOL to cover fees
        let tradablePoolsPairs = try await orcaSwap.getTradablePoolsPairs(
            fromMint: payingFeeTokenMint.base58EncodedString,
            toMint: PublicKey.wrappedSOLMint.base58EncodedString
        )

        // Get best poolsPair for best price
        guard let bestPools = try orcaSwap.findBestPoolsPairForEstimatedAmount(
            feeInSOL.total,
            from: tradablePoolsPairs
        ) else {
            throw FeeRelayerError.swapPoolsNotFound
        }

        let transactionFee = bestPools.getInputAmount(
            minimumAmountOut: feeInSOL.transaction,
            slippage: FeeRelayerConstants.topUpSlippage
        )
        let accountCreationFee = bestPools.getInputAmount(
            minimumAmountOut: feeInSOL.accountBalances,
            slippage: FeeRelayerConstants.topUpSlippage
        )

        return .init(
            transaction: transactionFee ?? 0,
            accountBalances: accountCreationFee ?? 0
        )
    }

//    private func isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
//        _ context: RelayContext,
//        payingTokenMint: String?
//    ) -> Bool {
//        let expectedTransactionFee = context.lamportsPerSignature * 2
//        return payingTokenMint == PublicKey.wrappedSOLMint.base58EncodedString &&
//            context.usageStatus.isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
//    }
}

public enum SendFeeCalculatorError: String, Swift.Error {
    case invalidPayingFeeWallet = "Paying fee wallet is not valid"
    case unknown = "Unknown error"
}
