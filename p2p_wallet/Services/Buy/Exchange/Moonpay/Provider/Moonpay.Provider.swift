//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation

extension Moonpay {
    enum MoonpayProviderError: Swift.Error {
        case unknown
    }

    enum MoonpayPaymentMethod: String {
        case creditDebitCard = "credit_debit_card"
        case sepaBankTransfer = "sepa_bank_transfer"
        case gbpBankTransfer = "gbp_bank_transfer"
    }

    class Provider {
        private let api: API

        init(api: API) { self.api = api }

        func getBuyQuote(
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

            var components = URLComponents(string: api.endpoint + "/v3/currencies/\(quoteCurrencyCode)/buy_quote")!
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

        func getSellQuote(
            baseCurrencyCode: String,
            quoteCurrencyCode: String,
            baseCurrencyAmount: Double,
            extraFeePercentage: Double? = 0
        ) async throws -> SellQuote {
            var params = [
                "apiKey": api.apiKey,
                "baseCurrencyCode": baseCurrencyCode,
                "areFeesIncluded": "true",
                // Undocumented params which makes results equal to web
                "fixed": "true",
                "regionalPricing": "true",
            ] as [String: Any]
            params["baseCurrencyAmount"] = baseCurrencyAmount
            params["quoteCurrencyCode"] = quoteCurrencyCode
            if let extraFeePercentage {
                params["extraFeePercentage"] = extraFeePercentage
            }

            var components = URLComponents(string: api.endpoint + "/v3/currencies/\(quoteCurrencyCode)/sell_quote")!
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

        func getPrice(for crypto: String, as currency: String) async throws -> Double {
            var components = URLComponents(string: api.endpoint + "/v3/currencies/\(crypto)/ask_price")!
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

        func getAllSupportedCurrencies() async throws -> Currencies {
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

        func bankTransferAvailability() async throws -> BankTransferAvailability {
            struct IpAddress: Codable {
                var alpha3: String?
            }

            var components = URLComponents(string: api.endpoint + "/v3/ip_address")!
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

        func ipAddresses() async throws -> IpAddressResponse {
            struct IpAddress: Codable {
                var alpha3: String?
            }

            var components = URLComponents(string: api.endpoint + "/v4/ip_address")!
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
    func bankTransferAvailableAlpha3Codes() -> [String] {
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
}

extension Moonpay.Provider {
    struct IpAddressResponse: Codable {
        var aplha2: String
        var alpha3: String
        var state: String
        var ipAddress: String
        var isAllowed: Bool
        var isBuyAllowed: Bool
        var isSellAllowed: Bool
    }
}
