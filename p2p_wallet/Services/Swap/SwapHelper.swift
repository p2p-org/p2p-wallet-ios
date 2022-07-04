// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

extension Array where Element == PayingFee {
    /**
     Get current token, that will be used as fee paying.
     */
    var totalToken: Token? {
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
