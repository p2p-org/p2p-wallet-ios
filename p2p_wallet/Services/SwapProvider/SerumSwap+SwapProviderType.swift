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
              let rate = rate,
              let slippage = slippage,
              rate != 0
        else {return nil}
        return inputAmount / rate * (1 - slippage)
    }
    
    func calculateNeededInputAmount(forReceivingEstimatedAmount estimatedAmount: Double?, rate: Double?, slippage: Double?) -> Double? {
        guard let estimatedAmount = estimatedAmount,
              let rate = rate,
              let slippage = slippage,
              rate != 0
        else {return nil}
        return estimatedAmount * rate * (1 + slippage)
    }
    
    func loadPrice(fromMint: String, toMint: String) -> Single<Double> {
        guard let fromMint = try? Self.PublicKey(string: fromMint),
              let toMint = try? Self.PublicKey(string: toMint)
        else {return .error(SolanaSDK.Error.unknown)}
        return loadFair(fromMint: fromMint, toMint: toMint)
    }
}
