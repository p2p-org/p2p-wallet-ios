//
// Created by Giang Long Tran on 14.02.2022.
//

import Foundation

struct Buy {
  public typealias ProcessingService = BuyProcessingServiceType
  public typealias Currency = BuyCurrencyType

  enum FiatCurrency: String, BuyCurrencyType {
    case usd = "usd"
  }

  enum CryptoCurrency: String, BuyCurrencyType {
    case eth = "eth"
    case sol = "sol"
    case usdt = "usdt"

    static let all: Set<CryptoCurrency> = [.eth, .sol, .usdt]
  }

  struct ExchangeInput {
    let amount: Double
    let currency: Currency

    func swap(with output: ExchangeOutput) -> ExchangeInput {
      .init(amount: output.amount, currency: output.currency)
    }
  }

  struct ExchangeOutput {
    let amount: Double
    let currency: Currency
    let fees: [PayingFee]
  }
}
