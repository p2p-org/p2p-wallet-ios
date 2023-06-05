import Foundation

/// HTTPClient for JSONRPC standard
public class JSONRPCHTTPClient {
    
    // MARK: - Properties

    private let endpoint: String
    private let httpClient: HTTPClient
    
    // MARK: - Initializer
    
    public init(
        endpoint: String,
        urlSession: HTTPURLSession = URLSession.shared
    ) {
        self.endpoint = endpoint
        self.httpClient = .init(
            urlSession: urlSession
        )
    }
    
    /// Invoke method
    public func invoke(
        method: String,
        header: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ],
        params: some Codable,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) async throws {
        
        // form endpoint
        let endpoint = JSONRPCEndpoint(
            baseURL: endpoint,
            method: .post,
            header: header,
            body: .init(
                method: method,
                params: params
            ),
            responseDecoder: JSONRPCResponseDecoder(
                jsonDecoder: jsonDecoder
            )
        )
        
        // invoke request, return nothing
        _ = try await httpClient.request(
            endpoint: endpoint,
            responseModel: String.self
        )
    }
    
    /// Call and expect result.
    public func call<Result: Codable, AdditionalError: Codable>(
        method: String,
        header: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ],
        params: some Codable,
        additionalError _: AdditionalError.Type = String.self,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) async throws -> Result {
        
        // form endpoint
        let endpoint = JSONRPCEndpoint(
            baseURL: endpoint,
            method: .post,
            header: header,
            body: .init(
                method: method,
                params: params
            ),
            responseDecoder: JSONRPCResponseDecoder(
                jsonDecoder: jsonDecoder
            )
        )
        
        // invoke request, return result
        return try await httpClient.request(
            endpoint: endpoint,
            responseModel: JSONRPCResponse<Result>.self
        )
            .result
    }
}
