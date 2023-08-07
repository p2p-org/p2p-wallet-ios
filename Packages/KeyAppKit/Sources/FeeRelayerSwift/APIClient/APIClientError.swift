import Foundation

/// FeeRelayer's APIClient Custom Error
enum APIClientError: Error {
    case invalidURL
    case custom(error: Error)
    case cantDecodeError
    case unknown
}
