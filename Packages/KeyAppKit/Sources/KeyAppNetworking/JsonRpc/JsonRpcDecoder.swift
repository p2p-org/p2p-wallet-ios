import Foundation

public struct JsonRpcDecoder: HTTPResponseDecoder {
    private let jsonDecoder: JSONDecoder
    
    public init(jsonDecoder: JSONDecoder) {
        self.jsonDecoder = jsonDecoder
    }
    
    public func decode<T: Decodable>(_ type: T.Type, data: Data, httpURLResponse response: HTTPURLResponse) throws -> T {
        let decodedResponse = try jsonDecoder.decode(JsonRpcResponseDto<T>.self, from: data)
        
        if let error = decodedResponse.error {
            throw error
        }
        
        switch response.statusCode {
        case 200 ... 299 where decodedResponse.result != nil:
            return decodedResponse.result!
        default:
            throw HTTPClientError.invalidResponse(response, data)
        }
    }
}
