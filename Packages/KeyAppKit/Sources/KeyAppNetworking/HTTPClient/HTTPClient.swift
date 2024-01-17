import Foundation

/// Default implementation for `HTTPClient`
public struct HTTPClient {
    // MARK: - Properties

    /// URLSession to handle network request
    private let urlSession: HTTPURLSession

    /// Decoder for response
    private let decoder: HTTPResponseDecoder

    // MARK: - Initializer

    /// HttpClient's initializer
    /// - Parameter urlSession: URLSession to handle network request
    /// - Parameter decoder: Decoder for response
    public init(
        urlSession: HTTPURLSession = URLSession.shared,
        decoder: HTTPResponseDecoder = JSONResponseDecoder()
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
    }
}

// MARK: - IHTTPClient

public extension HTTPClient {
    /// Send request to specific endpoint
    /// - Parameters:
    ///   - endpoint: endpoint to send request to
    ///   - responseModel: result type of model
    /// - Returns: specific result of `responseModel` type
    func request<T: Decodable, E: Decodable>(
        endpoint: HTTPEndpoint,
        responseModel: T.Type,
        errorModel: E.Type
    ) async throws -> T {
        /// URL assertion
        guard let url = URL(string: endpoint.urlString) else {
            throw HTTPClientError.invalidURL(endpoint.urlString)
        }

        // Form request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header

        if let body = endpoint.body {
            request.httpBody = body.data(using: .utf8)
        }

        // Retrieve data
        let (data, response) = try await urlSession.data(for: request)

        // Check cancellation
        try Task.checkCancellation()

        // Response assertion
        guard let response = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse(nil, data)
        }

        // Decode response
        return try decoder.decode(
            responseModel,
            errorType: errorModel,
            data: data,
            httpURLResponse: response
        )
    }
}
