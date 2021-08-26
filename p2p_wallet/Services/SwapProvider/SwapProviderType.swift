//
//  SwapProviderType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/08/2021.
//

import Foundation
import RxSwift

protocol SwapProviderType {
    func loadPrice(fromMint: String, toMint: String) -> Single<Double>
    func calculateAvailableAmount(
        sourceWallet: Wallet?
    ) -> Double?
    func calculateEstimatedAmount(
        inputAmount: Double?,
        rate: Double?,
        slippage: Double?
    ) -> Double?
    func calculateNeededInputAmount(
        forReceivingEstimatedAmount estimatedAmount: Double?,
        rate: Double?,
        slippage: Double?
    ) -> Double?
}
