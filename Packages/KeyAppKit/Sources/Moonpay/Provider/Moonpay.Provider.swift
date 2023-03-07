//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation

extension Moonpay {
    public enum MoonpayProviderError: Swift.Error {
        case unknown
    }

    public enum MoonpayPaymentMethod: String {
        case creditDebitCard = "credit_debit_card"
        case sepaBankTransfer = "sepa_bank_transfer"
        case gbpBankTransfer = "gbp_bank_transfer"
    }

    public class Provider {
        public let api: API
        public let serverSideAPI: API

        public init(api: API, serverSideAPI: API) {
            self.api = api
            self.serverSideAPI = serverSideAPI
        }

        public func getBuyQuote(
            baseCurrencyCode: String,
            quoteCurrencyCode: String,
            baseCurrencyAmount: Double?,
            quoteCurrencyAmount: Double?,
            paymentMethod: MoonpayPaymentMethod? = nil
        ) async throws -> BuyQuote {
            var params = [
                "apiKey": api.apiKey,
                "baseCurrencyCode": baseCurrencyCode,
                "areFeesIncluded": "true",
                // Undocumented params which makes results equal to web
                "fixed": "true",
                "regionalPricing": "true",
            ] as [String: Any]

            if let baseCurrencyAmount = baseCurrencyAmount {
                params["baseCurrencyAmount"] = baseCurrencyAmount
            }
            if let quoteCurrencyAmount = quoteCurrencyAmount {
                params["quoteCurrencyAmount"] = quoteCurrencyAmount
            }
            if let paymentMethod = paymentMethod {
                params["paymentMethod"] = paymentMethod.rawValue
            }

            var components = URLComponents(string: api.endpoint + "v3/currencies/\(quoteCurrencyCode)/buy_quote")!
            components.queryItems = params
                .mapValues { value -> Any in
                    value is Double ? String(value as! Double) : value
                }
                .compactMap { key, value in
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

        public func getSellQuote(
            baseCurrencyCode: String,
            quoteCurrencyCode: String,
            baseCurrencyAmount: Double,
            extraFeePercentage: Double? = 0
        ) async throws -> SellQuote {
            var params = [
                "apiKey": api.apiKey,
                "areFeesIncluded": "true",
                "baseCurrencyAmount": baseCurrencyAmount
            ] as [String: Any]
            params["quoteCurrencyCode"] = quoteCurrencyCode
            if let extraFeePercentage {
                params["extraFeePercentage"] = extraFeePercentage
            }

            var components = URLComponents(string: api.endpoint + "v3/currencies/\(baseCurrencyCode)/sell_quote")!
            components.queryItems = params
                .mapValues { value -> Any in
                    value is Double ? String(value as! Double) : value
                }
                .compactMap { key, value in
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
                return try JSONDecoder().decode(SellQuote.self, from: data)
            default:
                let data = try JSONDecoder().decode(API.ErrorResponse.self, from: data)
                throw Error.message(message: data.message)
            }
        }

        public func getPrice(for crypto: String, as currency: String) async throws -> Double {
            var components = URLComponents(string: api.endpoint + "v3/currencies/\(crypto)/ask_price")!
            let params = ["apiKey": api.apiKey]
            components.queryItems = params.map { key, value in
                URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            let urlRequest = URLRequest(url: components.url!)

            let (data, _) = try await URLSession.shared.data(from: urlRequest)
            guard let json = try? JSONDecoder().decode([String: Double].self, from: data)
            else { return 0 }
            return json[currency] ?? 0
        }

        public func getAllSupportedCurrencies() async throws -> Currencies {
            var components = URLComponents(string: api.endpoint + "v3/currencies")!
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

        public func bankTransferAvailability() async throws -> BankTransferAvailability {
            struct IpAddress: Codable {
                var alpha3: String?
            }

            var components = URLComponents(string: api.endpoint + "v3/ip_address")!
            let params = ["apiKey": api.apiKey]
            components.queryItems = params.map { key, value in
                URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            let urlRequest = URLRequest(url: components.url!)

            let (data, _) = try await URLSession.shared.data(from: urlRequest)
            guard
                let json = try? JSONDecoder().decode(IpAddress.self, from: data),
                let alpha3 = json.alpha3 else { return .init() }
            return BankTransferAvailability(
                gbp: alpha3 == "GBR",
                eur: bankTransferAvailableAlpha3Codes().contains(alpha3)
            )
        }

        public func ipAddresses() async throws -> IpAddressResponse {
            var components = URLComponents(string: api.endpoint + "v4/ip_address")!
            let params = ["apiKey": api.apiKey]
            components.queryItems = params.map { key, value in
                URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            let urlRequest = URLRequest(url: components.url!)

            let (data, _) = try await URLSession.shared.data(from: urlRequest)
            return try JSONDecoder().decode(IpAddressResponse.self, from: data)
        }
    }
}

extension Moonpay.Provider {
    public func bankTransferAvailableAlpha3Codes() -> [String] {
        [
            "AND",
            "AUT",
            "BEL",
            "BGR",
            "HRV",
            "CYP",
            "CZE",
            "DNK",
            "EST",
            "FIN",
            "FRA",
            "DEU",
            "GIB",
            "GRC",
            "HUN",
            "ISL",
            "IRL",
            "ITA",
            "LVA",
            "LIE",
            "LTU",
            "LUX",
            "MLT",
            "MCO",
            "NLD",
            "NOR",
            "POL",
            "PRT",
            "ROU",
            "SMR",
            "SVK",
            "SVN",
            "ESP",
            "SWE",
            "CHE",
            "GBR",
            "VAT",
        ]
    }

    public func UKAlpha3Code() -> String {
        "GBR"
    }

    public func USAlpha3Code() -> String {
        "USA"
    }
}

extension Moonpay.Provider {
    public struct IpAddressResponse: Codable {
        public var alpha2: String
        public var alpha3: String
        public var state: String
        public var ipAddress: String
        public var isAllowed: Bool
        public var isBuyAllowed: Bool
        public var isSellAllowed: Bool
    }
}

@available(iOS, deprecated: 15.0, message: "This extension is no longer necessary. Use API built into SDK")
extension URLSession {
    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: urlRequest) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}
