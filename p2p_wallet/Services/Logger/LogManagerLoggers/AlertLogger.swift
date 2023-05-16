import Foundation

struct AlertLoggerError<T: Codable>: Error, Codable {
    var title: String
    var message: T
}

final class AlertLogger: LogManagerLogger {
    var supportedLogLevels: [LogLevel] = [.alert]
    
    private let url = URL(string: "https://oncall.keyapp.org/integrations/v1/formatted_webhook/yQ9zMIbgg64nhdKC1TAViG53t/")!

    func log(event: String, logLevel: LogLevel, data: String?) {
        Task {
            // send request to endpoint
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = data?.data(using: .utf8) ?? Data()
//            _ = try? await URLSession.shared.data(from: urlRequest)
        }
    }

}
