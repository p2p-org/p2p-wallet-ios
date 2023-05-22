import Foundation

/// Decoder for response from `HTTPClient`
public protocol HTTPResponseDecoder {
    /// Decode data and response to needed type
    /// - Parameters:
    ///   - type: object type to be decoded to
    ///   - data: data to decode
    ///   - response: httpURLResponse from network
    /// - Returns: object of predefined type
    func decode<T: Decodable>(_ type: T.Type, data: Data, httpURLResponse response: HTTPURLResponse) throws -> T
}

/// ResponseDecoder for JSON type
public struct JSONResponseDecoder {
    
    // MARK: - Properties
    
    /// Default native `JSONDecoder`
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Initializers
    
    /// `JSONResponseDecoder` initializer
    /// - Parameter jsonDecoder: Default native `JSONDecoder`
    public init(jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.jsonDecoder = jsonDecoder
    }
}

// MARK: - HTTPResponseDecoder

extension JSONResponseDecoder: HTTPResponseDecoder {
    /// Decode data and response to needed type
    /// - Parameters:
    ///   - type: object type to be decoded to
    ///   - data: data to decode
    ///   - response: httpURLResponse from network
    /// - Returns: object of predefined type
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
