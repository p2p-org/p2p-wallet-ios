import Foundation

public protocol HTTPURLSession {
    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPURLSession {}
