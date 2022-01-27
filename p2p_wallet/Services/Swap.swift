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
    func load() -> Completable
    
    func getPoolPair(
        from sourceMint: String,
        to destinationMint: String,
        amount: UInt64,
        as inputMode: Swap.InputMode
    ) -> Single<[Swap.PoolsPair]>
    
    func swap(
        sourceAddress: String,
        sourceTokenMint: String?,
        destinationAddress: String,
        destinationTokenMint: String?,
        payingTokenAddress: String,
        payingTokenMint: String,
        poolPair: Swap.PoolsPair,
        amount: UInt64,
        slippage: Double
    ) -> Single<[String]>
    
    func getFees(
        myWalletsMints: [String],
        fromWalletPubkey: String,
        toWalletPubkey: String?,
        bestPoolsPair: OrcaSwap.PoolsPair?,
        inputAmount: Double?,
        slippage: Double,
        lamportsPerSignature: UInt64,
        minRentExempt: UInt64
    ) throws -> Swap.FeeInfo
    
    func findPosibleDestinationMints(fromMint: String) throws -> [String]
}

struct Swap {
    typealias Service = SwapServiceType
    
    enum InputMode {
        case source
        case target
    }
    
    // TODO: make this class abstract
    struct PoolsPair {
        // TODO: Hide direct access. We have to abstract it
        let orcaPoolPair: OrcaSwap.PoolsPair
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
        public let transactionFees: UInt64
        public let accountCreationFee: UInt64?
        public let liquidityProviderFees: [UInt64]
    }
}

class SwapServiceWithRelayImpl: SwapServiceType {
    private let solanaClient: SolanaSDK
    private let accountStorage: SolanaSDKAccountStorage
    private let feeRelayApi: FeeRelayerAPIClientType
    private let orcaSwap: OrcaSwapType
    private var feeRelay: FeeRelayer.Relay?
    
    // TODO: Remove me
    @Injected var notificationsService: NotificationsServiceType
    
    init(solanaClient: SolanaSDK, accountStorage: SolanaSDKAccountStorage, feeRelay: FeeRelayerAPIClientType, orcaSwap: OrcaSwapType) {
        self.solanaClient = solanaClient
        self.accountStorage = accountStorage
        self.feeRelayApi = feeRelay
        self.orcaSwap = orcaSwap
    }
    
    func load() -> Completable {
        do {
            feeRelay = try FeeRelayer.Relay(
                apiClient: feeRelayApi,
                solanaClient: solanaClient,
                accountStorage: accountStorage,
                orcaSwapClient: orcaSwap
            )
    
            return .zip(
                orcaSwap.load(),
                feeRelay!.load()
            )
        } catch {
            return .error(error)
        }
    }
    
    func getSwapInfo(from sourceToken: SolanaSDK.Token, to destinationToken: SolanaSDK.Token) -> Swap.SwapInfo {
        // Determine a mode for paying fee
        var payingTokenMode: Swap.PayingTokenMode = .any
        if sourceToken.isNativeSOL && !destinationToken.isNativeSOL {
            payingTokenMode = .onlySol
        } else if !sourceToken.isNativeSOL && destinationToken.isNativeSOL {
            payingTokenMode = .onlySol
        }
        
        return .init(payingTokenMode: payingTokenMode)
    }
    
    func getPoolPair(
        from sourceMint: String,
        to destinationMint: String,
        amount: UInt64,
        as inputMode: Swap.InputMode
    ) -> Single<[Swap.PoolsPair]> {
        orcaSwap.getTradablePoolsPairs(fromMint: sourceMint, toMint: destinationMint)
        .map { result in result.map { $0.toPoolsPair() } }
    }
    
    func getFees(
        myWalletsMints: [String],
        fromWalletPubkey: String,
        toWalletPubkey: String?,
        bestPoolsPair: OrcaSwap.PoolsPair?,
        inputAmount: Double?,
        slippage: Double,
        lamportsPerSignature: UInt64,
        minRentExempt: UInt64
    ) throws -> Swap.FeeInfo {
        let result = try orcaSwap.getFees(
            myWalletsMints: myWalletsMints,
            fromWalletPubkey: fromWalletPubkey,
            toWalletPubkey: toWalletPubkey,
            bestPoolsPair: bestPoolsPair,
            inputAmount: inputAmount,
            slippage: slippage,
            lamportsPerSignature: lamportsPerSignature,
            minRentExempt: minRentExempt
        )
        
        return .init(
            transactionFees: result.transactionFees,
            accountCreationFee: result.accountCreationFee,
            liquidityProviderFees: result.liquidityProviderFees
        )
    }
    
    public func findPosibleDestinationMints(fromMint: String) throws -> [String] { try orcaSwap.findPosibleDestinationMints(fromMint: fromMint) }
    
    func swap(
        sourceAddress: String,
        sourceTokenMint: String?,
        destinationAddress: String,
        destinationTokenMint: String?,
        payingTokenAddress: String,
        payingTokenMint: String,
        poolPair: Swap.PoolsPair,
        amount: UInt64,
        slippage: Double
    ) -> Single<[String]> {
        if sourceAddress == accountStorage.account?.publicKey.base58EncodedString {
            // sol -> spl, replay doesn't support it
            guard let decimals = poolPair.orcaPoolPair[0].getTokenADecimals() else {
                return .error(OrcaSwapError.invalidPool)
            }
            
            notificationsService.showInAppNotification(.message("Use orca"))
            return orcaSwap.swap(
                fromWalletPubkey: sourceAddress,
                toWalletPubkey: destinationAddress,
                bestPoolsPair: poolPair.orcaPoolPair,
                amount: amount.convertToBalance(decimals: decimals),
                slippage: slippage,
                isSimulation: false
            ).map { response in [response.transactionId] }
        } else if destinationAddress == accountStorage.account?.publicKey.base58EncodedString {
            // spl -> sol, bug in error
            guard let decimals = poolPair.orcaPoolPair[0].getTokenADecimals() else {
                return .error(OrcaSwapError.invalidPool)
            }
            
            notificationsService.showInAppNotification(.message("Use orca"))
            return orcaSwap.swap(
                fromWalletPubkey: sourceAddress,
                toWalletPubkey: destinationAddress,
                bestPoolsPair: poolPair.orcaPoolPair,
                amount: amount.convertToBalance(decimals: decimals),
                slippage: slippage,
                isSimulation: false
            ).map { response in [response.transactionId] }
        }
        
        guard let feeRelay = feeRelay else { return .error(SolanaSDK.Error.other("Fee relay is not ready")) }
        guard let sourceTokenMint = sourceTokenMint else { return .error(SolanaSDK.Error.other("Invalid source mint address")) }
        guard let destinationTokenMint = destinationTokenMint else { return .error(SolanaSDK.Error.other("Invalid destination mint address")) }
        
        // spl -> spl, use relay
        notificationsService.showInAppNotification(.message("Use relay"))
        
        return feeRelay.topUpAndSwap(
            sourceToken: FeeRelayer.Relay.TokenInfo(address: sourceAddress, mint: sourceTokenMint),
            destinationTokenMint: destinationTokenMint,
            destinationAddress: destinationAddress,
            payingFeeToken: FeeRelayer.Relay.TokenInfo(address: sourceAddress, mint: sourceTokenMint),
            swapPools: poolPair.orcaPoolPair,
            inputAmount: amount,
            slippage: slippage
        )
    }
}

fileprivate extension OrcaSwap.PoolsPair {
    func toPoolsPair() -> Swap.PoolsPair { .init(orcaPoolPair: self) }
}

extension Array where Element == Swap.PoolsPair {
    func findBestPoolsPairForEstimatedAmount(_ estimatedAmount: UInt64) -> Swap.PoolsPair? {
        guard count > 0 else { return nil }
        
        var bestPools: Swap.PoolsPair?
        var bestEstimatedAmount: UInt64 = 0
        
        for pair in self {
            guard let estimatedAmount = pair.orcaPoolPair.getInputAmount(fromEstimatedAmount: estimatedAmount)
                else { continue }
            if estimatedAmount > bestEstimatedAmount {
                bestEstimatedAmount = estimatedAmount
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
            guard let estimatedAmount = pair.orcaPoolPair.getOutputAmount(fromInputAmount: inputAmount)
                else { continue }
            if estimatedAmount > bestEstimatedAmount {
                bestEstimatedAmount = estimatedAmount
                bestPools = pair
            }
        }
        
        return bestPools
    }
}
