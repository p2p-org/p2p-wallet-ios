//
//  FiatConvertable.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/12/2020.
//

import Foundation

protocol FiatConvertable {
    var amount: Double? {get}
    var symbol: String {get}
}

extension FiatConvertable {
    var priceInUSD: Double? {
        PricesManager.bonfida.prices.value.first(where: {$0.from == symbol})?.value
    }
    var amountInUSD: Double {
        amount * priceInUSD
    }
}
