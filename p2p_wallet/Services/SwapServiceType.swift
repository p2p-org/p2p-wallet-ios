//
//  SwapManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/01/2022.
//

import Foundation
import RxSwift
import SolanaSwift
import FeeRelayerSwift
import OrcaSwapSwift

protocol SwapServiceType {
    func getPoolPair(
        from sourceMint: String,
        to destinationMint: String,
        amount: UInt64,
        as inputMode: SwapServiceType.InputMode
    ) -> Single<SwapServiceType.PoolsPairsResult?>
    
    func swap(
        sourceAddress: String,
        sourceTokenMint: String,
        destinationAddress: String,
        destinationTokenMint: String?,
        payingTokenAddress: String,
        payingTokenMint: String,
        poolPair: SwapServiceType.PoolsPair,
        amount: UInt64,
        slippage: Double
    ) throws -> Single<[String]>
}

struct SwapServiceType {
    enum InputMode {
        case source
        case target
    }
    
    struct PoolsPairsResult {
        let best: PoolsPair
        let other: [PoolsPair]
    }
    
    struct PoolsPair {
        fileprivate let orcaPoolPair: OrcaSwap.PoolsPair
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
}

class SwapServiceImpl: SwapServiceType {
    let solanaClient: SolanaSDK
    let accountStorage: SolanaSDKAccountStorage
    let feeRelay: FeeRelayerAPIClientType
    let orcaSwap: OrcaSwapType
    
    init(solanaClient: SolanaSDK, accountStorage: SolanaSDKAccountStorage, feeRelay: FeeRelayerAPIClientType, orcaSwap: OrcaSwapType) {
        self.solanaClient = solanaClient
        self.accountStorage = accountStorage
        self.feeRelay = feeRelay
        self.orcaSwap = orcaSwap
    }
    
    func getSwapInfo(from sourceToken: SolanaSDK.Token, to destinationToken: SolanaSDK.Token) -> SwapServiceType.SwapInfo {
        // Determine a mode for paying fee
        var payingTokenMode: SwapServiceType.PayingTokenMode = .any
        if (sourceToken.isNativeSOL && !destinationToken.isNativeSOL) {
            payingTokenMode = .onlySol
        } else if (!sourceToken.isNativeSOL && destinationToken.isNativeSOL) {
            payingTokenMode = .onlySol
        }
        
        return .init(payingTokenMode: payingTokenMode)
    }
    
    func getPoolPair(
        from sourceMint: String,
        to destinationMint: String,
        amount: UInt64,
        as inputMode: SwapServiceType.InputMode
    ) -> Single<SwapServiceType.PoolsPairsResult?> {
        orcaSwap.getTradablePoolsPairs(fromMint: sourceMint, toMint: destinationMint)
            .map { [weak self] pairs -> SwapServiceType.PoolsPairsResult? in
                guard let self = self, pairs.count > 0 else { return nil }
                
                var bestPoolPair: OrcaSwap.PoolsPair
                switch (inputMode) {
                case .source:
                    bestPoolPair = try self.orcaSwap.findBestPoolsPairForInputAmount(amount, from: pairs)!
                case .target:
                    bestPoolPair = try self.orcaSwap.findBestPoolsPairForEstimatedAmount(amount, from: pairs)!
                }
                
                return .init(
                    best: bestPoolPair.toPoolsPair(),
                    other: pairs.filter { $0 != bestPoolPair }.map { $0.toPoolsPair() }
                )
            }
    }
    
    func swap(
        sourceAddress: String,
        sourceTokenMint: String,
        destinationAddress: String,
        destinationTokenMint: String?,
        payingTokenAddress: String,
        payingTokenMint: String,
        poolPair: SwapServiceType.PoolsPair,
        amount: UInt64,
        slippage: Double
    ) throws -> Single<[String]> {
        let relay = try FeeRelayer.Relay(
            apiClient: feeRelay,
            solanaClient: solanaClient,
            accountStorage: accountStorage,
            orcaSwapClient: orcaSwap
        )
        
        return relay
            .load()
            .andThen(
                relay.topUpAndSwap(
                    sourceToken: FeeRelayer.Relay.TokenInfo(address: sourceAddress, mint: sourceTokenMint),
                    destinationTokenMint: destinationAddress,
                    destinationAddress: destinationTokenMint,
                    payingFeeToken: FeeRelayer.Relay.TokenInfo(address: payingTokenAddress, mint: payingTokenMint),
                    swapPools: poolPair.orcaPoolPair,
                    inputAmount: amount,
                    slippage: slippage
                )
            )
    }
}

fileprivate extension OrcaSwap.PoolsPair {
    func toPoolsPair() -> SwapServiceType.PoolsPair { .init(orcaPoolPair: self) }
}