//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation

extension Moonpay {
    enum MoonpayProviderError: Swift.Error {
        case unknown
    }

    class Provider {
        private let api: API

        init(api: API) { self.api = api }

        func getBuyQuote(
            baseCurrencyCode: String,
            quoteCurrencyCode: String,
            baseCurrencyAmount: Double?,
            quoteCurrencyAmount: Double?
        ) async throws -> BuyQuote {
            var params = [
                "apiKey": api.apiKey,
                "baseCurrencyCode": baseCurrencyCode,
                "areFeesIncluded": "true",
            ] as [String: Any]

            if let baseCurrencyAmount = baseCurrencyAmount {
                params["baseCurrencyAmount"] = baseCurrencyAmount
            }
            if let quoteCurrencyAmount = quoteCurrencyAmount {
                params["quoteCurrencyAmount"] = quoteCurrencyAmount
            }

            var components = URLComponents(string: api.endpoint + "/currencies/\(quoteCurrencyCode)/buy_quote")!
            components.queryItems = params.compactMap { key, value in
                guard let value = value as? String else { return nil }
                return URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            let urlRequest = URLRequest(url: components.url!)

            let (data, response) = try await URLSession.shared.data(from: urlRequest)
            guard let response = response as? HTTPURLResponse else {
                throw MoonpayProviderError.unknown
            }
            switch response.statusCode {
            case 200 ... 299:
                return try JSONDecoder().decode(BuyQuote.self, from: data)
            default:
                let data = try JSONDecoder().decode(API.ErrorResponse.self, from: data)
                throw Error.message(message: data.message)
            }
        }

        func getPrice(for crypto: String, as currency: String) async throws -> Double {
            guard let url = URL(string: api.endpoint + "/currencies/\(crypto)/ask_price")
            else {
                throw MoonpayProviderError.unknown
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONDecoder().decode([String: Double].self, from: data)
            else { return 0 }
            return json[currency] ?? 0
        }

        func getAllSupportedCurrencies() async throws -> Currencies {
            var components = URLComponents(string: api.endpoint + "/currencies")!
            let params = ["apiKey": api.apiKey]
            components.queryItems = params.map { key, value in
                URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            let urlRequest = URLRequest(url: components.url!)

            let (data, response) = try await URLSession.shared.data(from: urlRequest)
            guard let response = response as? HTTPURLResponse else {
                throw MoonpayProviderError.unknown
            }
            switch response.statusCode {
            case 200 ... 299:
                return try JSONDecoder().decode(Currencies.self, from: data)
            default:
                let data = try JSONDecoder().decode(API.ErrorResponse.self, from: data)
                throw Error.message(message: data.message)
            }
        }
    }
}
