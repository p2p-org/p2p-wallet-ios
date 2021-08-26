//
//  SerumSwap+SwapProviderType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/08/2021.
//

import Foundation
import RxSwift

extension SerumSwap: SwapProviderType {
    func calculateAvailableAmount(sourceWallet: Wallet?) -> Double? {
        sourceWallet?.amount
    }
    
    func calculateEstimatedAmount(inputAmount: Double?, rate: Double?, slippage: Double?) -> Double? {
        guard let inputAmount = inputAmount,
              let fair = rate,
              fair != 0
        else {return nil}
        return FEE_MULTIPLIER * (inputAmount / fair)
    }
    
    func calculateNeededInputAmount(forReceivingEstimatedAmount estimatedAmount: Double?, rate: Double?, slippage: Double?) -> Double? {
        guard let estimatedAmount = estimatedAmount,
              let fair = rate,
              fair != 0
        else {return nil}
        return estimatedAmount * fair / FEE_MULTIPLIER
    }
    
    func loadPrice(fromMint: String, toMint: String) -> Single<Double> {
        guard let fromMint = try? Self.PublicKey(string: fromMint),
              let toMint = try? Self.PublicKey(string: toMint)
        else {return .error(SolanaSDK.Error.unknown)}
        return loadFair(fromMint: fromMint, toMint: toMint)
    }
}
