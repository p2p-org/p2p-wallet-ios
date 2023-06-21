import Foundation

public protocol HTTPURLSession {
    func data(for urlRequest: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPURLSession {}
