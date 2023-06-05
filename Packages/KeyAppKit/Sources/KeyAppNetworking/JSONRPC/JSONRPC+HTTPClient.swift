import Foundation

// MARK: - IHTTPClient

extension HTTPClient {
    public static func jsonRPC(
        urlSession: HTTPURLSession = URLSession.shared,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) -> HTTPClient {
        HTTPClient(
            urlSession: urlSession,
            decoder: JSONRPCResponseDecoder(jsonDecoder: jsonDecoder)
        )
    }
}
