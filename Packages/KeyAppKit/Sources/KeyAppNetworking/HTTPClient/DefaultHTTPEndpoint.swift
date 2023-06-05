import Foundation

/// Common implementation for HTTPEndpoint
public struct DefaultHTTPEndpoint<Body: Encodable, ResponseDecoder: HTTPResponseDecoder>: HTTPEndpoint {
    public let baseURL: String
    public let path: String
    public let method: HTTPMethod
    public let header: [String : String]
    public let body: Body?
    public let responseDecoder: ResponseDecoder
    
    
    public init(
        baseURL: String,
        path: String,
        method: HTTPMethod,
        header: [String : String],
        body: Body?,
        responseDecoder: ResponseDecoder = JSONResponseDecoder(jsonDecoder: .init())
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.header = header
        self.body = body
        self.responseDecoder = responseDecoder
    }
}

extension DefaultHTTPEndpoint where Body == String, ResponseDecoder == JSONResponseDecoder {
    public init(
        baseURL: String,
        path: String,
        method: HTTPMethod,
        header: [String : String]
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.header = header
        self.body = nil
        self.responseDecoder = JSONResponseDecoder(jsonDecoder: .init())
    }
}

/// Public extension for HTTPClient for handy use of DefaultHTTPEndpoint
public extension HTTPClient {
    /// Send request to specific endpoint
    /// - Parameters:
    ///   - endpoint: default endpoint to send request to
    ///   - responseModel: result type of model
    /// - Returns: specific result of `responseModel` type
    func request<T: Decodable, Body: Encodable, ResponseDecoder: HTTPResponseDecoder>(
        endpoint: DefaultHTTPEndpoint<Body, ResponseDecoder>,
        responseModel: T.Type
    ) async throws -> T {
        try await request(endpoint: endpoint as (any HTTPEndpoint), responseModel: responseModel)
    }
}
