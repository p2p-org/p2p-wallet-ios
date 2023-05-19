import Foundation

/// Decoder for response from `HTTPClient`
public protocol HTTPResponseDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

/// `JSONDecoder` as `HTTPResponseDecoder`
extension JSONDecoder: HTTPResponseDecoder {}
