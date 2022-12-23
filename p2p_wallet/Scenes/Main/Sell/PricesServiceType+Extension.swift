//
//  PricesServiceType+Extension.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2022.
//

import Foundation
import Sell

extension PricesService: SellPriceProvider {
    func getCurrentPrice(for coinName: String) -> Double? {
        currentPrice(for: coinName)?.value
    }
}
