import Foundation

/// Common implementation for HTTPEndpoint
public struct DefaultHTTPEndpoint: HTTPEndpoint {
    public let baseURL: String
    public let path: String
    public let method: HTTPMethod
    public let header: [String : String]
    public let body: String?
    
    
    public init(
        baseURL: String,
        path: String,
        method: HTTPMethod,
        header: [String : String],
        body: String? = nil
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.header = header
        self.body = body
    }
}

/// Public extension for HTTPClient for handy use of DefaultHTTPEndpoint
public extension HTTPClient {
    /// Send request to specific endpoint
    /// - Parameters:
    ///   - endpoint: default endpoint to send request to
    ///   - responseModel: result type of model
    /// - Returns: specific result of `responseModel` type
    func request<T: Decodable>(
        endpoint: DefaultHTTPEndpoint,
        responseModel: T.Type
    ) async throws -> T {
        try await request(endpoint: endpoint as HTTPEndpoint, responseModel: responseModel)
    }
}
