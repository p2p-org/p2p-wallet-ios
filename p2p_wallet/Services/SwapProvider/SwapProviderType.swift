//
//  SwapProviderType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/08/2021.
//

import Foundation
import RxSwift

protocol SwapProviderType {
    /// Price loading for a single pair of token
    func loadPrice(
        fromMint: String,
        toMint: String
    ) -> Single<Double>

    /// Define if fee relayer is enabled for current wallet pair
    func isFeeRelayerEnabled(
        source: Wallet?,
        destination: Wallet?
    ) -> Bool

    /// Calculate fee for swapping
    /// - Returns: collection of fee's name and fee's detail
    func calculateFees(
        sourceWallet: Wallet?,
        destinationWallet: Wallet?,
        lamportsPerSignature: SolanaSDK.Lamports?,
        creatingAccountFee: SolanaSDK.Lamports?
    ) -> Single<[PayingFee]>

    func calculateMinOrderSize(
        fromMint: String,
        toMint: String
    ) -> Single<Double>

    /// Maximum amount that user can use for swapping
    func calculateAvailableAmount(
        sourceWallet: Wallet?,
        fees: [PayingFee]?
    ) -> Double?

    /// Estimated amount that user can get after swapping
    func calculateEstimatedAmount(
        inputAmount: Double?,
        rate: Double?,
        slippage: Double?
    ) -> Double?

    /// Input amount needed for receiving an estimated amount
    func calculateNeededInputAmount(
        forReceivingEstimatedAmount estimatedAmount: Double?,
        rate: Double?,
        slippage: Double?
    ) -> Double?

    /// Logo shown at bottom, after "Powered by" text
    func logoView() -> UIView

    /// Main function
    func swap(
        fromWallet: SolanaSDK.Wallet,
        toWallet: SolanaSDK.Wallet,
        amount: Double,
        slippage: Double,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID>
}
