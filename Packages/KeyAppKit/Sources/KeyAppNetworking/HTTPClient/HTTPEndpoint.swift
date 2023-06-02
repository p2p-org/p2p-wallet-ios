import Foundation

/// Endpoint for specific `HTTPClient` network call
public protocol HTTPEndpoint<Body> {
    associatedtype Body: Encodable
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var header: [String: String] { get }
    var body: Body? { get }
}

public extension HTTPEndpoint {
    var urlString: String {
        baseURL + path
    }
    
    func getEncodedBody() throws -> Data? {
        guard let body else {
            return nil
        }
        return try JSONEncoder().encode(body)
    }
}
