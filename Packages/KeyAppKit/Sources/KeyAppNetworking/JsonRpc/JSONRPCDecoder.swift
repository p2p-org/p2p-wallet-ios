import Foundation

public struct JSONRPCDecoder: HTTPResponseDecoder {
    private let jsonDecoder: JSONDecoder
    
    public init(jsonDecoder: JSONDecoder) {
        self.jsonDecoder = jsonDecoder
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decodedResponse = try jsonDecoder.decode(JsonRpcResponseDto<T>.self, from: data)
        
        if let error = decodedResponse.error {
            throw error
        }
        
        if let result = decodedResponse.result {
            return result
        }
        
        throw HTTPClientError.invalidResponse(nil, data)
    }
}
