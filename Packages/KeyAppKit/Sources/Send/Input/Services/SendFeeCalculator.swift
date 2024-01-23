import KeyAppKitCore
import SolanaSwift

public class SendFeeCalculator {
    // MARK: - Properties

    private let sendService: SendRPCService

    // MARK: - Init

    public init(sendService: SendRPCService) {
        self.sendService = sendService
    }

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

        var expectedFee = FeeAmount(
            transaction: transactionFee,
            accountBalances: isAssociatedTokenUnregister ? token.minRentExemption ?? 0 : 0
        )

        // Check if any frees transactionFee
        if limit.networkFee.isAvailable(
            forAmount: expectedFee.transaction
        ) {
            expectedFee.transaction = 0
        }

        // Check if any frees accountBalancesFee
        if limit.tokenAccountRent.isAvailable(
            forAmount: expectedFee.accountBalances
        ) {
            expectedFee.accountBalances = 0
        }

        return expectedFee
    }

    public func calculateFeeInPayingToken(
        feeInSOL: FeeAmount,
        payingFeeTokenMint: PublicKey
    ) async throws -> FeeAmount? {
        // If token is sol, no conversion needed
        if payingFeeTokenMint == PublicKey.wrappedSOLMint {
            return feeInSOL
        }

        // Assert fee is not zero
        guard feeInSOL.total != 0 else {
            return .zero
        }

        // Get rates from sendService
        return try await withThrowingTaskGroup(of: UInt64.self) { group in
            group.addTask { [weak self] in
                if let self, feeInSOL.transaction > 0 {
                    return try await sendService.getTokenAmount(
                        amount: feeInSOL.transaction,
                        mints: [payingFeeTokenMint.base58EncodedString]
                    ).first?.uint64Value ?? 0
                }
                return 0
            }

            group.addTask { [weak self] in
                if let self, feeInSOL.accountBalances > 0 {
                    return try await sendService.getTokenAmount(
                        amount: feeInSOL.accountBalances,
                        mints: [payingFeeTokenMint.base58EncodedString]
                    ).first?.uint64Value ?? 0
                }
                return 0
            }

            let rates = try await group.reduce(into: [UInt64]()) { $0.append($1) }
            return FeeAmount(transaction: rates[0], accountBalances: rates[1])
        }
    }

    public func getAvailableWalletsToPayFee(
        wallets: [SolanaAccount],
        feeInSOL: FeeAmount,
        whiteListMints: [String]
    ) async -> [SolanaAccount] {
        let filteredWallets = wallets
            .filter { $0.lamports > 0 && whiteListMints.contains($0.mintAddress) }

        var feeWallets = [SolanaAccount]()
        for element in filteredWallets {
            if element.token.mintAddress == PublicKey.wrappedSOLMint
                .base58EncodedString, element.lamports >= feeInSOL.total
            {
                feeWallets.append(element)
                continue
            }
            let feeAmount = try? await calculateFeeInPayingToken(
                feeInSOL: feeInSOL,
                payingFeeTokenMint: PublicKey(string: element.token.mintAddress)
            )
            if (feeAmount?.total ?? 0) <= element.lamports {
                feeWallets.append(element)
            }
        }

        return feeWallets
    }
}

public enum SendFeeCalculatorError: String, Swift.Error {
    case invalidPayingFeeWallet = "Paying fee wallet is not valid"
    case unknown = "Unknown error"
}
