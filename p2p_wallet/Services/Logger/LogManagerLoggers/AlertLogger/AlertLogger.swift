import Foundation

final class AlertLogger: LogManagerLogger {
    var supportedLogLevels: [LogLevel] = [.alert]

    private let url = URL(string: .secretConfig("SWAP_ERROR_LOGGER_ENDPOINT")!)!

    func log(event: String, logLevel: LogLevel, data: String?) {
        Task {
            // send request to endpoint
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = AlertLoggerError(title: event, message: data ?? "")
            urlRequest.httpBody = try JSONEncoder().encode(body)
            _ = try? await URLSession.shared.data(for: urlRequest)
        }
    }

}

// MARK: - Models

private struct AlertLoggerError: Error, Codable {
    var title: String
    var message: String
}
