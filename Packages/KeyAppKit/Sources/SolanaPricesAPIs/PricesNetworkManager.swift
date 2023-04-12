import Foundation

public protocol PricesNetworkManager {
    func get(urlString: String) async throws -> Data
}

public struct DefaultPricesNetworkManager: PricesNetworkManager {
    let urlSession: URLSession

    public init(urlSession: URLSession? = nil) {
        if let urlSession {
            self.urlSession = urlSession
        } else {
            let config = URLSessionConfiguration.default

            config.timeoutIntervalForRequest = 5
            config.timeoutIntervalForResource = 5

            self.urlSession = .init(configuration: config)
        }
    }

    public func get(urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw PricesAPIError.invalidURL
        }
        try Task.checkCancellation()
        let (data, response) = try await urlSession.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            throw PricesAPIError.invalidResponseStatusCode(nil)
        }
        switch response.statusCode {
        case 200 ... 299:
            try Task.checkCancellation()
            return data
        default:
            try Task.checkCancellation()
            throw PricesAPIError.invalidResponseStatusCode(response.statusCode)
        }
    }
}
