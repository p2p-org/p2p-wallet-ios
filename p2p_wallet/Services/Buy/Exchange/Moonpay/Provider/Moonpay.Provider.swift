//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation
import RxAlamofire
import RxSwift

extension Moonpay {
    class Provider {
        private let api: API

        init(api: API) { self.api = api }

        func getBuyQuote(
            baseCurrencyCode: String,
            quoteCurrencyCode: String,
            baseCurrencyAmount: Double?,
            quoteCurrencyAmount: Double?
        ) -> Single<BuyQuote> {
            var params = [
                "apiKey": api.apiKey,
                "baseCurrencyCode": baseCurrencyCode,
                "areFeesIncluded": "true",
            ] as [String: Any]

            if let baseCurrencyAmount = baseCurrencyAmount { params["baseCurrencyAmount"] = baseCurrencyAmount }
            if let quoteCurrencyAmount = quoteCurrencyAmount { params["quoteCurrencyAmount"] = quoteCurrencyAmount }

            return request(.get, api.endpoint + "/currencies/\(quoteCurrencyCode)/buy_quote", parameters: params)
                .responseData()
                .map { response, data in
                    switch response.statusCode {
                    case 200 ... 299:
                        return try JSONDecoder().decode(BuyQuote.self, from: data)
                    default:
                        let data = try JSONDecoder().decode(API.ErrorResponse.self, from: data)
                        throw Error.message(message: data.message)
                    }
                }
                .take(1)
                .asSingle()
        }

        func getPrice(for crypto: String, as currency: String) -> Single<Double> {
            request(.get, api.endpoint + "/currencies/\(crypto)/ask_price", parameters: ["apiKey": api.apiKey])
                .responseJSON()
                .take(1)
                .asSingle()
                .map { response -> Double in
                    guard let json = response.value as? [String: Double] else { return 0 }
                    return json[currency] ?? 0
                }
        }

        func getAllSupportedCurrencies() -> Single<Currencies> {
            request(.get, api.endpoint + "/currencies", parameters: ["apiKey": api.apiKey])
                .responseData()
                .map { response, data in
                    switch response.statusCode {
                    case 200 ... 299:
                        return try JSONDecoder().decode(Currencies.self, from: data)
                    default:
                        let data = try JSONDecoder().decode(API.ErrorResponse.self, from: data)
                        throw Error.message(message: data.message)
                    }
                }
                .take(1)
                .asSingle()
        }
    }
}
