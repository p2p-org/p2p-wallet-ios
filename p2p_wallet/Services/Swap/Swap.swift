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

/// Swap configuration
protocol SwapServicePoolsPair {
    func getMinimumAmountOut(inputAmount: UInt64, slippage: Double) -> UInt64?

    func getInputAmount(fromEstimatedAmount estimatedAmount: UInt64) -> UInt64?

    func getOutputAmount(fromInputAmount inputAmount: UInt64) -> UInt64?
}

///  This protocol describes an interface for swapping service.
///  In general you have to call `load` method first to prepare a service.
protocol SwapServiceType {
    /// Prepare swap service.
    func load() async throws

    /// Determine the all exchange route.
    func getPoolPair(
        from sourceMint: String,
        to destinationMint: String
    ) async throws -> [Swap.PoolsPair]

    /// Process swap
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
    ) async throws -> [String]

    /// Calculate fee for swapping
    func getFees(
        sourceMint: String,
        destinationAddress: String?,
        destinationToken: Token,
        bestPoolsPair: Swap.PoolsPair?,
        payingWallet: Wallet?,
        inputAmount: Double?,
        slippage: Double
    ) async throws -> Swap.FeeInfo

    /// Calculate fee for swapping
    func findPosibleDestinationMints(
        fromMint: String
    ) throws -> [String]

    /// Calculate amount needed for paying fee in paying token
    func calculateNetworkFeeInPayingToken(
        networkFee: FeeAmount,
        payingTokenMint: String
    ) async throws -> FeeAmount?
}

enum SwapError: Error {
    case incompatiblePoolsPair
    case feeRelayIsNotReady
}
