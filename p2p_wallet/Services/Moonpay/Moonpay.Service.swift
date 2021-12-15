//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation
import RxSwift
import RxAlamofire

protocol MoonpayService {
    func getBuyQuote(baseCurrencyCode: String, quoteCurrencyCode: String, baseCurrencyAmount: Double) -> Single<Moonpay.BuyQuote>
}

extension Moonpay {
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
                    "baseCurrencyAmount": baseCurrencyAmount
                ]
            ).responseData()
                .take(1)
                .asSingle()
                .map { (_, data) in try JSONDecoder().decode(BuyQuote.self, from: data) }
        }
    }
}

