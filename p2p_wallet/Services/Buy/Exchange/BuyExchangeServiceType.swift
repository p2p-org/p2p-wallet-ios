//
// Created by Giang Long Tran on 21.02.2022.
//

import Foundation
import RxSwift

protocol BuyExchangeServiceType {
    func convert(input: Buy.ExchangeInput, to currency: Buy.Currency) -> Single<Buy.ExchangeOutput>
    func getExchangeRate(from fiatCurrency: Buy.FiatCurrency, to cryptoCurrency: Buy.CryptoCurrency) -> Single<Buy.ExchangeRate>
}
