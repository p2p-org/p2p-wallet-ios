import Foundation

/// Endpoint for specific `HTTPClient` network call
public protocol HTTPEndpoint<Body> {
    associatedtype Body: Encodable
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var header: [String: String] { get }
    var body: Body? { get }

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
