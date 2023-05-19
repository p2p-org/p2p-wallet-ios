import Foundation

/// HttpClient to handle http network requests
public protocol IHTTPClient {
    /// Send request to specific endpoint
    /// - Parameters:
    ///   - endpoint: endpoint to send request to
    ///   - responseModel: result type of model
    /// - Returns: specific result of `responseModel` type
    func sendRequest<T: Decodable>(
        endpoint: HTTPEndpoint,
        responseModel: T.Type
    ) async throws -> T
}

/// Default implementation for `IHTTPClient`
public class HTTPClient {

    // MARK: - Properties
    
    /// URLSession to handle network request
    private let urlSession: URLSession
    
    /// Decoder for response
    private let decoder: HTTPResponseDecoder
    
    // MARK: - Initializer
    
    /// HttpClient's initializer
    /// - Parameter urlSession: URLSession to handle network request
    /// - Parameter decoder: Decoder for response
    public init(
        urlSession: URLSession = .shared,
        decoder: HTTPResponseDecoder = JSONResponseDecoder()
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
    }
}

extension HTTPClient: IHTTPClient {
    /// Send request to specific endpoint
    /// - Parameters:
    ///   - endpoint: endpoint to send request to
    ///   - responseModel: result type of model
    /// - Returns: specific result of `responseModel` type
    public func sendRequest<T: Decodable>(
        endpoint: HTTPEndpoint,
        responseModel: T.Type
    ) async throws -> T {
        /// URL assertion
        let urlString = endpoint.baseURL + endpoint.path
        guard let url = URL(string: urlString) else {
            throw HTTPClientError.invalidURL(urlString)
        }
        
        // Form request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header
        
        if let body = endpoint.body {
            request.httpBody = body.data(using: .utf8)
        }
        
        // Retrieve data
        let (data, response) = try await urlSession.data(from: request)
        
        // Check cancellation
        try Task.checkCancellation()
        
        // Response assertion
        guard let response = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse(nil, data)
        }
        
        // Decode response
        return try decoder.decode(responseModel, data: data, httpURLResponse: response)
    }
}
