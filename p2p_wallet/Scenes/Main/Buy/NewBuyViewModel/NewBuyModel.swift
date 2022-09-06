//
//  NewBuyModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.09.2022.
//

import Foundation

protocol BuyValue {
    var formattedValue: String { get }
    var formattedConcurrency: String { get }
}

struct BuyFiatValue: BuyValue {
    var value: Double
    var currency: Buy.FiatCurrency

    var formattedValue: String { value.toString() }
    var formattedConcurrency: String { currency.name }
}

struct BuyCryptoCurrency: BuyValue {
    var value: Double
    var currency: Buy.CryptoCurrency

    var formattedValue: String { value.toString() }
    var formattedConcurrency: String { currency.name }
}

enum BuyPaymentMethod: String, DefaultsSerializable {
    case card
    case bank

    func info() -> BuyPaymentMethodInfo {
        switch self {
        case .bank:
            return .init(
                fee: "1%",
                duration: "~17 hours",
                name: "Bank transfer",
                icon: UIImage.buyBank
            )
        case .card:
            return .init(
                fee: "4%",
                duration: "instant",
                name: "Card",
                icon: UIImage.buyCard
            )
        }
    }
}

struct BuyPaymentMethodInfo: Equatable {
    var fee: String
    var duration: String
    var name: String
    var icon: UIImage
}
