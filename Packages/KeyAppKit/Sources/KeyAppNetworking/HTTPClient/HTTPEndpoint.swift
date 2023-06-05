import Foundation

/// Endpoint for specific `HTTPClient` network call
public protocol HTTPEndpoint {
    associatedtype Body: Encodable
    associatedtype ResponseDecoder: HTTPResponseDecoder
    
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var header: [String: String] { get }
    var body: Body? { get }
    
    var responseDecoder: ResponseDecoder { get }

    func encodeBody() throws -> Data?
}

public extension HTTPEndpoint {
    var urlString: String {
        baseURL + path
    }
    
    func encodeBody() throws -> Data? {
        guard let body else {
            return nil
        }
        if let body = body as? String {
            return body.data(using: .utf8)
        }
        return try JSONEncoder().encode(body)
    }
}

public extension HTTPEndpoint where ResponseDecoder == JSONResponseDecoder {
    var responseDecoder: ResponseDecoder {
        JSONResponseDecoder(jsonDecoder: .init())
    }
}
