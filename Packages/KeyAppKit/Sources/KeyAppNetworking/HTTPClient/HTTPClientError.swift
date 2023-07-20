import Foundation

/// Custom HTTPClientError
public enum HTTPClientError: Error {
    /// Something went wrong when constructing URL
    case invalidURL(String)
    /// Invalid response from endpoint
    case invalidResponse(HTTPURLResponse?, Data)
}
