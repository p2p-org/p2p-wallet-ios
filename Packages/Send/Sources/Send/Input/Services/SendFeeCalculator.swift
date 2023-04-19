import FeeRelayerSwift
import OrcaSwapSwift
import SolanaSwift

public protocol SendFeeCalculator: AnyObject {
    func getFees(
        from token: Token,
        recipient: Recipient,
        recipientAdditionalInfo: SendInputState.RecipientAdditionalInfo,
        payingTokenMint: String?,
        feeRelayerContext context: RelayContext
    ) async throws -> FeeAmount?
}

public class SendFeeCalculatorImpl: SendFeeCalculator {
    private let feeRelayerCalculator: RelayFeeCalculator

    public init(feeRelayerCalculator: RelayFeeCalculator) { self.feeRelayerCalculator = feeRelayerCalculator }

    // MARK: - Fees calculator

    public func getFees(
        from token: Token,
        recipient: Recipient,
        recipientAdditionalInfo: SendInputState.RecipientAdditionalInfo,
        payingTokenMint: String?,
        feeRelayerContext context: RelayContext
    ) async throws -> FeeAmount? {
        var transactionFee: UInt64 = 0

        // owner's signature
        transactionFee += context.lamportsPerSignature

        // feePayer's signature
        transactionFee += context.lamportsPerSignature

        var isAssociatedTokenUnregister = false

        if token.isNativeSOL {
            // User transfer native SOL
            isAssociatedTokenUnregister = false
        } else {
            switch recipient.category {
            case let .solanaTokenAddress(walletAddress, _):
                let associatedAccount = try PublicKey.associatedTokenAddress(
                    walletAddress: walletAddress,
                    tokenMintAddress: try PublicKey(string: token.address)
                )

                isAssociatedTokenUnregister = !recipientAdditionalInfo.splAccounts
                    .contains(where: { $0.pubkey == associatedAccount.base58EncodedString })
            case .solanaAddress, .username:
                let associatedAccount = try PublicKey.associatedTokenAddress(
                    walletAddress: try PublicKey(string: recipient.address),
                    tokenMintAddress: try PublicKey(string: token.address)
                )

                isAssociatedTokenUnregister = !recipientAdditionalInfo.splAccounts
                    .contains(where: { $0.pubkey == associatedAccount.base58EncodedString })
            default:
                break
            }
        }

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(context, payingTokenMint: payingTokenMint) {
            // subtract the fee payer signature cost
            transactionFee -= context.lamportsPerSignature
        }

        let expectedFee = FeeAmount(
            transaction: transactionFee,
            accountBalances: isAssociatedTokenUnregister ? context.minimumTokenAccountBalance : 0
        )

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(context, payingTokenMint: payingTokenMint) {
            return expectedFee
        }
        
        return try await feeRelayerCalculator.calculateNeededTopUpAmount(
            context,
            expectedFee: expectedFee,
            payingTokenMint: try? PublicKey(string: payingTokenMint)
        )
    }

    private func isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
        _ context: RelayContext,
        payingTokenMint: String?
    ) -> Bool {
        let expectedTransactionFee = context.lamportsPerSignature * 2
        return payingTokenMint == PublicKey.wrappedSOLMint.base58EncodedString &&
            context.usageStatus.isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
    }
}

public enum SendFeeCalculatorError: String, Swift.Error {
    case invalidPayingFeeWallet = "Paying fee wallet is not valid"
    case unknown = "Unknown error"
}
