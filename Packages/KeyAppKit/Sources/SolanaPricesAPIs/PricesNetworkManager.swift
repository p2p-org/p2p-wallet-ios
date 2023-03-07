import Foundation

public protocol PricesNetworkManager {
    func get(urlString: String) async throws -> Data
}

public struct DefaultPricesNetworkManager: PricesNetworkManager {
    public init() {}
    public func get(urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw PricesAPIError.invalidURL
        }
        try Task.checkCancellation()
        let (data, response) = try await URLSession.shared.data(from: url)
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
