import Foundation

enum LogLevel: String {
    case info
    case error
    case request
    case response
    case event
    case warning
    case debug
}

protocol LogManagerLogger {
    var supportedLogLevels: [LogLevel] { get set }
    func log(event: String, logLevel: LogLevel, data: String?)
}

protocol LogManager {
    func setProviders(_ providers: [LogManagerLogger])
    func log(event: String, logLevel: LogLevel, data: String?, shouldLogEvent: () -> Bool)
}

class DefaultLogManager: LogManager {
    static let shared = DefaultLogManager()

    private(set) var providers: [LogManagerLogger] = []
    private var queue = DispatchQueue(label: "DefaultLogManager", qos: .utility, attributes: [.concurrent])

    func setProviders(_ providers: [LogManagerLogger] = [SentryLogger()]) {
        self.providers = providers
    }

    func log(event: String, logLevel: LogLevel, data: String? = nil, shouldLogEvent: () -> Bool) {
        guard shouldLogEvent() else { return }
        providers.forEach { provider in
            queue.async {
                provider.log(event: event, logLevel: logLevel, data: data)
            }
        }
    }
}
