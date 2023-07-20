import Foundation

/// Endpoint for specific `HTTPClient` network call
public protocol HTTPEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var header: [String: String] { get }
    var body: String? { get }
}

public extension HTTPEndpoint {
    var urlString: String {
        baseURL + path
    }
}
