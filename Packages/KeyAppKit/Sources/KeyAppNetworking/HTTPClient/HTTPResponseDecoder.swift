import Foundation

/// Decoder for response from `HTTPClient`
public protocol HTTPResponseDecoder {
    func decode<T: Decodable>(_ type: T.Type, data: Data, httpURLResponse response: HTTPURLResponse) throws -> T
}

/// ResponseDecoder for JSON type
public class JSONResponseDecoder: HTTPResponseDecoder {
    
    private let jsonDecoder: JSONDecoder
    
    public init(jsonDecoder: JSONDecoder = .init()) {
        self.jsonDecoder = jsonDecoder
    }
    
    public func decode<T: Decodable>(_ type: T.Type, data: Data, httpURLResponse response: HTTPURLResponse) throws -> T
    {
        switch response.statusCode {
        case 200 ... 299:
            return try JSONDecoder().decode(type, from: data)
        default:
            throw HTTPClientError.invalidResponse(response, data)
        }
    }
}
