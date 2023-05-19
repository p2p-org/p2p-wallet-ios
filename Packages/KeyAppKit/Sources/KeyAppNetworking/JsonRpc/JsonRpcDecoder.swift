import Foundation

/// ResponseDecoder for JsonRpc type
public struct JsonRpcDecoder {

    // MARK: - Properties

    /// Default native `JSONDecoder`
    private let jsonDecoder: JSONDecoder

    // MARK: - Initializer
    
    /// `JsonRpcDecoder` initializer
    /// - Parameter jsonDecoder: Default native `JSONDecoder`
    public init(jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.jsonDecoder = jsonDecoder
    }
}

extension JsonRpcDecoder: HTTPResponseDecoder {
    /// Decode data and response to needed type
    /// - Parameters:
    ///   - type: object type to be decoded to
    ///   - data: data to decode
    ///   - response: httpURLResponse from network
    /// - Returns: object of predefined type
    public func decode<T: Decodable>(_ type: T.Type, data: Data, httpURLResponse response: HTTPURLResponse) throws -> T {
        
        // Check status code
        switch response.statusCode {
        case 200 ... 299:
            // try to decode response
            do {
                return try jsonDecoder.decode(JsonRpcResponseDto<T>.self, from: data).result
            } catch {
                throw decodeRpcError(from: data) ?? error
            }
        default:
            throw decodeRpcError(from: data) ?? HTTPClientError.invalidResponse(response, data)
        }
    }
    
    // MARK: - Helpers
    
    /// Custom error return from rpc endpoint
    private func decodeRpcError(from data: Data) -> JsonRpcError? {
        try? jsonDecoder.decode(JsonRpcResponseErrorDto.self, from: data).error
    }
}
