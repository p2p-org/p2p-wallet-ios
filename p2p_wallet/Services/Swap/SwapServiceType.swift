//
//  SwapManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/01/2022.
//

import Foundation
import RxSwift
import SolanaSwift
import OrcaSwapSwift

///  This protocol describes an interface for swapping service.
///  In general you have to call `load` method first to prepare a service.
protocol SwapServiceType {
    /// Initialize swap service.
    func initialize() async throws
    
    /// Reload swap service.
    func reload() async throws

    /// Determine the all exchange route.
    func getTradablePoolsPairs(
        from sourceMint: String,
        to destinationMint: String
    ) async throws -> [PoolsPair]
    
    /// Find best route (poolsPair for swapping) for user's input amount
    func findBestPoolsPairForInputAmount(
        _ inputAmount: UInt64,
        from poolsPairs: [PoolsPair]
    ) throws -> PoolsPair?
    
    /// Find best route (poolsPair for swapping) for user's estimated amount
    func findBestPoolsPairForEstimatedAmount(
        _ estimatedAmount: UInt64,
        from poolsPairs: [PoolsPair]
    ) throws -> PoolsPair?

    /// Process swap
    func swap(
        sourceAddress: String,
        sourceTokenMint: String,
        destinationAddress: String?,
        destinationTokenMint: String,
        payingTokenAddress: String?,
        payingTokenMint: String?,
        poolsPair: PoolsPair,
        amount: UInt64,
        slippage: Double
    ) async throws -> [String]

    /// Calculate fee for swapping
    func getFees(
        sourceMint: String,
        destinationAddress: String?,
        destinationToken: Token,
        bestPoolsPair: PoolsPair?,
        payingWallet: Wallet?,
        inputAmount: Double?,
        slippage: Double
    ) async throws -> SwapFeeInfo

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

struct SwapFeeInfo {
    /**
     Get all fees categories. For example: account creation fee, network fee, etc.
     */
    let fees: [PayingFee]
}
