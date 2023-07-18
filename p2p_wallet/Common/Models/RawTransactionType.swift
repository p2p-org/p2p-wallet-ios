import Foundation
import KeyAppKitCore
import OrcaSwapSwift
import SolanaSwift

protocol RawTransactionType {
    func createRequest() async throws -> String
    var mainDescription: String { get }
    var payingFeeWallet: SolanaAccount? { get }
    var feeAmount: FeeAmount { get }
}

struct SwapMetaInfo {
    let swapMAX: Bool
    let swapUSD: Double
}

protocol SwapRawTransactionType: RawTransactionType {
    var authority: String? { get }
    var sourceWallet: SolanaAccount { get }
    var destinationWallet: SolanaAccount { get }
    var fromAmount: Double { get }
    var toAmount: Double { get }
    var slippage: Double { get }
    var metaInfo: SwapMetaInfo { get }
}

struct OrcaSwapTransaction: SwapRawTransactionType {
    let swapService: SwapServiceType
    let sourceWallet: SolanaAccount
    let destinationWallet: SolanaAccount
    let payingFeeWallet: SolanaAccount?
    let authority: String?
    let poolsPair: PoolsPair
    let fromAmount: Double
    let toAmount: Double
    let slippage: Double
    let feeDetails: [PayingFee]
    let metaInfo: SwapMetaInfo

    var feeAmount: FeeAmount {
        feeDetails.networkFees ?? .zero
    }

    var mainDescription: String {
        "\(fromAmount.tokenAmountFormattedString(symbol: sourceWallet.token.symbol)) → \(toAmount.tokenAmountFormattedString(symbol: destinationWallet.token.symbol))"
    }

    func createRequest() async throws -> String {
        // check if payingWallet has enough balance to cover fee
        if let payingWallet = payingFeeWallet,
           let currentAmount = payingFeeWallet?.lamports,
           feeAmount.total > currentAmount
        {
            throw SolanaError.other(
                L10n.yourAccountDoesNotHaveEnoughToCoverFees(payingWallet.token.symbol)
                    + ". "
                    + L10n
                    .needsAtLeast(
                        "\(feeAmount.total.convertToBalance(decimals: payingWallet.token.decimals)) \(payingWallet.token.symbol)"
                    )
                    + ". "
                    + L10n.pleaseChooseAnotherTokenAndTryAgain
            )
        }

        return try await swapService.swap(
            sourceAddress: sourceWallet.pubkey!,
            sourceTokenMint: sourceWallet.mintAddress,
            destinationAddress: destinationWallet.pubkey,
            destinationTokenMint: destinationWallet.mintAddress,
            payingTokenAddress: payingFeeWallet?.pubkey,
            payingTokenMint: payingFeeWallet?.mintAddress,
            poolsPair: poolsPair,
            amount: fromAmount.toLamport(decimals: sourceWallet.token.decimals),
            slippage: slippage
        )
        .last ?? ""
    }
}

struct CloseTransaction: RawTransactionType {
    var payingFeeWallet: SolanaAccount?

    var feeAmount: SolanaSwift.FeeAmount

    let closingWallet: SolanaAccount
    let reimbursedAmount: UInt64

    var mainDescription: String {
        L10n.closeAccount(closingWallet.token.symbol)
    }

    func createRequest() async throws -> String {
        fatalError("Not implemented")
        // guard let pubkey = closingWallet.pubkey else {
        //     return .error(Error.unknown)
        // }
        // return closeTokenAccount(tokenPubkey: pubkey)
    }
}

// MARK: - Transaction status

enum ProcessTransactionError: Swift.Error {
    case notEnoughNumberOfConfirmations
}
