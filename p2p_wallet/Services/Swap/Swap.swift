//
//  SwapManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/01/2022.
//

import Foundation
import RxSwift
import SolanaSwift

struct Swap {
    typealias Service = SwapServiceType
    typealias PoolsPair = SwapServicePoolsPair
    typealias Error = SwapError

    enum InputMode {
        case source
        case target
    }

    enum PayingTokenMode {
        /// Allow to use any token to pay a fee
        case any
        /// Only allow to use native sol to pay a fee
        case onlySol
    }

    struct SwapInfo {
        /// This property defines a mode for paying fee.
        let payingTokenMode: PayingTokenMode
    }

    struct FeeInfo {
        /**
         Get all fees categories. For example: account creation fee, network fee, etc.
         */
        let fees: [PayingFee]
    }
}

/**
 Swap configuration
 */
protocol SwapServicePoolsPair {
    func getMinimumAmountOut(
        inputAmount: UInt64,
        slippage: Double
    ) -> UInt64?

    func getInputAmount(
        fromEstimatedAmount estimatedAmount: UInt64
    ) -> UInt64?

    func getOutputAmount(
        fromInputAmount inputAmount: UInt64
    ) -> UInt64?
}

/**
 This protocol describes an interface for swapping service.
 In general you have to call `load` method first to prepare a service.
 */
protocol SwapServiceType {
    /**
     Prepare swap service.
     - Returns: `Completable`.
     */
    func load() -> Completable

    /**
     Determine the all exchange route.
     - Parameters:
       - sourceMint: the source mint address.
       - destinationMint: the destination mint address.
       - amount: the amount of swapping.
       - inputMode: set amount as `source` or `target`.
     - Returns: Exchange route.
     */
    func getPoolPair(
        from sourceMint: String,
        to destinationMint: String,
        amount: UInt64,
        as inputMode: Swap.InputMode
    ) -> Single<[Swap.PoolsPair]>

    /**
     Process swap
     - Parameters:
       - sourceAddress: the source address of token in user's wallet.
       - sourceTokenMint: the source mint address of source address.
       - destinationAddress: the destination address of token in wallet, that user wants to swap to.
       - destinationTokenMint: the destination mint address of destination address.
       - payingTokenAddress: the address of token, that will be used as fee paying address.
       - payingTokenMint: the mint address of paying token.
       - poolsPair: the user's selected exchange route. Normally it's the best.
       - amount: the amount of source token.
       - slippage:
     - Returns: The id of transaction.
     */
    func swap(
        sourceAddress: String,
        sourceTokenMint: String,
        destinationAddress: String?,
        destinationTokenMint: String,
        payingTokenAddress: String?,
        payingTokenMint: String?,
        poolsPair: Swap.PoolsPair,
        amount: UInt64,
        slippage: Double
    ) -> Single<[String]>

    /**
     Calculate fee for swapping
     - Parameters:
       - sourceAddress: the source address of token in user's wallet.
       - availableSourceMintAddresses:
       - destinationAddress: the destination address of token in wallet, that user wants to swap to.
       - destinationToken: the destination token.
       - bestPoolsPair: the user's selected exchange route
       - inputAmount: the amount of swapping.
       - slippage:
       - lamportsPerSignature: the fee per signature
       - minRentExempt:
     - Returns: The detailed fee information
     - Throws:
     */
    func getFees(
        sourceAddress: String,
        sourceMint: String,
        availableSourceMintAddresses: [String],
        destinationAddress: String?,
        destinationToken: SolanaSDK.Token,
        bestPoolsPair: Swap.PoolsPair?,
        payingWallet: Wallet?,
        inputAmount: Double?,
        slippage: Double,
        lamportsPerSignature: UInt64,
        minRentExempt: UInt64
    ) -> Single<Swap.FeeInfo>

    /**
     Find all possible destination mint addresses.
     - Parameter fromMint:
     - Returns: The list of mint addresses
     - Throws:
     */
    func findPosibleDestinationMints(
        fromMint: String
    ) throws -> [String]

    /**
     Calculate amount needed for paying fee in paying token
     */
    func calculateNetworkFeeInPayingToken(
        networkFee: SolanaSDK.FeeAmount,
        payingTokenMint: String
    ) -> Single<SolanaSDK.FeeAmount?>
}

enum SwapError: Error {
    case incompatiblePoolsPair
    case feeRelayIsNotReady
}

extension Array where Element == PayingFee {
    /**
     Get current token, that will be used as fee paying.
     */
    var totalToken: SolanaSDK.Token? {
        first(where: { $0.type == .transactionFee })?.token
    }

    /**
     Get total fee amount in fee token.
     */
    var totalDecimal: Double {
        if let totalToken = totalToken {
            let totalFees = filter { $0.token.symbol == totalToken.symbol && $0.type != .liquidityProviderFee }
            let decimals = totalFees.first?.token.decimals ?? 0
            return totalFees
                .reduce(UInt64(0)) { $0 + $1.lamports }
                .convertToBalance(decimals: decimals)
        }
        return 0.0
    }

    var totalLamport: UInt64 {
        if let totalToken = totalToken {
            let totalFees = filter { $0.token.symbol == totalToken.symbol && $0.type != .liquidityProviderFee }
            return totalFees.reduce(UInt64(0)) { $0 + $1.lamports }
        }
        return 0
    }
}

extension Array where Element == Swap.PoolsPair {
    func findBestPoolsPairForEstimatedAmount(_ estimatedAmount: UInt64) -> Swap.PoolsPair? {
        guard count > 0 else { return nil }

        var bestPools: Swap.PoolsPair?
        var bestInputAmount: UInt64 = .max

        for pair in self {
            guard let inputAmount = pair.getInputAmount(fromEstimatedAmount: estimatedAmount)
            else { continue }
            if inputAmount < bestInputAmount {
                bestInputAmount = inputAmount
                bestPools = pair
            }
        }

        return bestPools
    }

    func findBestPoolsPairForInputAmount(_ inputAmount: UInt64) -> Swap.PoolsPair? {
        guard count > 0 else { return nil }

        var bestPools: Swap.PoolsPair?
        var bestEstimatedAmount: UInt64 = 0

        for pair in self {
            guard let estimatedAmount = pair.getOutputAmount(fromInputAmount: inputAmount)
            else { continue }
            if estimatedAmount > bestEstimatedAmount {
                bestEstimatedAmount = estimatedAmount
                bestPools = pair
            }
        }

        return bestPools
    }
}
