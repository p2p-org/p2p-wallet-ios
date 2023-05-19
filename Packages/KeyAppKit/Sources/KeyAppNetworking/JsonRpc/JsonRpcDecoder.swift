import Foundation

public struct JsonRpcDecoder: HTTPResponseDecoder {
    private let jsonDecoder: JSONDecoder
    
    public init(jsonDecoder: JSONDecoder) {
        self.jsonDecoder = jsonDecoder
    }
    
    public func decode<T: Decodable>(_ type: T.Type, data: Data, httpURLResponse response: HTTPURLResponse) throws -> T {
        
        // Check status code
        switch response.statusCode {
        case 200 ... 299:
            // try to decode response
            do {
                return try jsonDecoder.decode(JsonRpcResponseDto<T>.self, from: data).result
            } catch {
                if let rpcError = decodeRpcError(from: data) {
                    throw rpcError
                }
                throw error
            }
        default:
            if let rpcError = decodeRpcError(from: data) {
                throw rpcError
            }
            throw HTTPClientError.invalidResponse(response, data)
        }
    }
    
    // MARK: - Helpers

    private func decodeRpcError(from data: Data) -> JsonRpcError? {
        try? jsonDecoder.decode(JsonRpcResponseErrorDto.self, from: data).error
    }
}
