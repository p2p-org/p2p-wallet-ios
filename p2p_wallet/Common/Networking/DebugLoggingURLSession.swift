import Foundation
import KeyAppNetworking
import OSLog

struct DebugLoggingURLSession: HTTPURLSession {
    func data(for urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        let logger = Logger(subsystem: "test", category: "test")
        logger.warning("\(urlRequest.cURL())")
        let (data, res) = try await URLSession.shared.data(for: urlRequest)
        if let string = String(data: data, encoding: .utf8) {
            logger.warning("\(string)")
        }
        return (data, res)
    }
}
