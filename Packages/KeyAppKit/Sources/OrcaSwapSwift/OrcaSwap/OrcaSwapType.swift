//
//  File.swift
//  
//
//  Created by Chung Tran on 06/05/2022.
//

import Foundation
import SolanaSwift

public protocol OrcaSwapType {
    func load() async throws
    func getMint(tokenName: String) -> String?
    func findPosibleDestinationMints(fromMint: String) throws -> [String]
    func getTradablePoolsPairs(fromMint: String, toMint: String) async throws -> [PoolsPair]
    func findBestPoolsPairForInputAmount(_ inputAmount: UInt64, from poolsPairs: [PoolsPair], prefersDirectSwap: Bool) throws -> PoolsPair?
    func findBestPoolsPairForEstimatedAmount(_ estimatedAmount: UInt64, from poolsPairs: [PoolsPair], prefersDirectSwap: Bool) throws -> PoolsPair?
    func getLiquidityProviderFee(
        bestPoolsPair: PoolsPair?,
        inputAmount: Double?,
        slippage: Double
    ) throws -> [UInt64]
    func getNetworkFees(
        myWalletsMints: [String],
        fromWalletPubkey: String,
        toWalletPubkey: String?,
        bestPoolsPair: PoolsPair?,
        inputAmount: Double?,
        slippage: Double,
        lamportsPerSignature: UInt64,
        minRentExempt: UInt64
    ) async throws -> FeeAmount
    func prepareForSwapping(
        fromWalletPubkey: String,
        toWalletPubkey: String?,
        bestPoolsPair: PoolsPair,
        amount: Double,
        feePayer: PublicKey?, // nil if the owner is the fee payer
        slippage: Double
    ) async throws -> ([PreparedSwapTransaction], String?)
    func swap(
        fromWalletPubkey: String,
        toWalletPubkey: String?,
        bestPoolsPair: PoolsPair,
        amount: Double,
        slippage: Double,
        isSimulation: Bool
    ) async throws -> SwapResponse
}

public extension OrcaSwapType {
    func findBestPoolsPairForInputAmount(_ inputAmount: UInt64,from poolsPairs: [PoolsPair]) throws -> PoolsPair? {
        try findBestPoolsPairForInputAmount(inputAmount, from: poolsPairs, prefersDirectSwap: false)
    }
    func findBestPoolsPairForEstimatedAmount(_ estimatedAmount: UInt64, from poolsPairs: [PoolsPair]) throws -> PoolsPair? {
        try findBestPoolsPairForEstimatedAmount(estimatedAmount, from: poolsPairs, prefersDirectSwap: false)
    }
}
