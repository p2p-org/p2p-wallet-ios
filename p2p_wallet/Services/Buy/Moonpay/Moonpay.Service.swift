//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation
import RxSwift
import RxAlamofire

protocol MoonpayService {
    func getPrice(for crypto: String, as currency: Moonpay.Currency) -> Single<Double>
    func getBuyQuote(baseCurrencyCode: String, quoteCurrencyCode: String, baseCurrencyAmount: Double) -> Single<Moonpay.BuyQuote>
}

extension Moonpay {
    enum Currency {
        case usd
        case eur
        case gbp
        
        func toString() -> String {
            switch self {
            case .usd: return "USD"
            case .eur: return "EUR"
            case .gbp: return "GBP"
            }
        }
    }
        
    class MoonpayServiceImpl: MoonpayService {
        private let api: API
        
        init(api: API) { self.api = api }
        
        struct BuyQuoteRequest: Encodable {
            let apiKey: String
            let baseCurrencyCode: String
            let baseCurrencyAmount: Int
        }
        
        func getBuyQuote(baseCurrencyCode: String, quoteCurrencyCode: String, baseCurrencyAmount: Double) -> Single<BuyQuote> {
            request(.get, api.endpoint + "/currencies/\(quoteCurrencyCode)/buy_quote",
                parameters: [
                    "apiKey": api.apiKey,
                    "baseCurrencyCode": baseCurrencyCode,
                    "baseCurrencyAmount": baseCurrencyAmount,
                    "areFeesIncluded": true,
                ]
            ).responseData()
                .map { response, data in
                    switch response.statusCode {
                    case 200...299:
                        return try JSONDecoder().decode(BuyQuote.self, from: data)
                    default:
                        let data = try JSONDecoder().decode(API.ErrorResponse.self, from: data)
                        throw Error.default(message: data.message)
                    }
                }
                .take(1)
                .asSingle()
        }
        
        func getPrice(for crypto: String, as currency: Currency) -> Single<Double> {
            request(.get, api.endpoint + "/currencies/\(crypto)/ask_price", parameters: ["apiKey": api.apiKey])
                .responseJSON()
                .take(1)
                .asSingle()
                .map { response -> Double in
                    guard let json = response.value as? [String: Double] else { return 0 }
                    return json[currency.toString()] ?? 0
                }
        }
    }
}
