// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public enum SolendMath {
    public struct Reward {
        /// Token symbol
        public let symbol: String

        /// Amount of reward pro second
        public let rate: Double
    }

    /// Calculate rewards from each deposits.
    ///
    /// - Parameters:
    ///   - marketInfos: A list of market info
    ///   - userDeposits: A list of user's deposits
    /// - Returns: A list reward
    public static func reward(
        marketInfos: [SolendMarketInfo],
        userDeposits: [SolendUserDeposit]
    ) -> [Reward] {
        userDeposits
            .map { (deposit: SolendUserDeposit) -> Reward in
                guard let marketInfo = marketInfos.first(where: { $0.symbol == deposit.symbol }) else {
                    return .init(symbol: deposit.symbol, rate: 0)
                }

                let depositAmount = Double(deposit.depositedAmount) ?? 0
                let apy = Double(marketInfo.supplyInterest) ?? 0
                let rewardRate = depositAmount * (1 + apy/100) / 31_536_000
                return .init(symbol: deposit.symbol, rate: rewardRate)
            }
    }
}
