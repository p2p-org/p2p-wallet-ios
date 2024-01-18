import Foundation

/// Implementation for `JSONRPCHTTPClient`
public struct JSONRPCHTTPClient {
    // MARK: - Properties

    /// URLSession to handle network request
    private let urlSession: HTTPURLSession

    /// Decoder for response
    private let decoder = JSONRPCDecoder()

    // MARK: - Initializer

    /// HttpClient's initializer
    /// - Parameter urlSession: URLSession to handle network request
    /// - Parameter decoder: Decoder for response
    public init(
        urlSession: HTTPURLSession = URLSession.shared
    ) {
        self.urlSession = urlSession
    }

    /// Invoke request and do not expect returning data
    public func invoke<P: Encodable, E: Decodable>(
        baseURL: String,
        path: String,
        method: HTTPMethod = .post,
        header: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ],
        body: JSONRPCRequestDto<P>,
        errorDataType: E.Type = EmptyData.self
    ) async throws {
        let httpClient = HTTPClient(
            urlSession: urlSession,
            decoder: decoder
        )

        _ = try await httpClient.request(
            endpoint: DefaultHTTPEndpoint(
                baseURL: baseURL,
                path: path,
                method: method,
                header: header,
                body: body
            ),
            responseModel: JSONRPCResponseDto<String>.self,
            errorModel: errorDataType
        )
    }

    /// Send request to specific JSONRPC endpoint
    public func request<P: Encodable, T: Decodable, E: Decodable>(
        baseURL: String,
        path: String = "",
        method: HTTPMethod = .post,
        header: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ],
        body: JSONRPCRequestDto<P>,
        responseModel _: T.Type,
        errorDataType: E.Type = EmptyData.self
    ) async throws -> T {
        let httpClient = HTTPClient(
            urlSession: urlSession,
            decoder: decoder
        )

        let response = try await httpClient.request(
            endpoint: DefaultHTTPEndpoint(
                baseURL: baseURL,
                path: path,
                method: method,
                header: header,
                body: body
            ),
            responseModel: JSONRPCResponseDto<T>.self,
            errorModel: errorDataType
        )
        return response.result
    }
}
