import Foundation
import Sentry

class SentryLogger: LogProvider {
    private var queue = DispatchQueue(label: "SentryLogger", qos: .utility)

    var supportedLogLevels: [DefaultLogLevel] = [.error, .alert]

    func log(event: String, logLevel: DefaultLogLevel, data: String?) {
        guard supportedLogLevels.contains(logLevel) else { return }
        queue.sync {
            let sentryEvent = Event(level: convertDefaultLogLevelToCustomLogLevel(logLevel))
            sentryEvent.message = SentryMessage(formatted: event)
            SentrySDK.capture(event: sentryEvent) { scope in
                scope.setExtras([
                    "value": data ?? "",
                    "key": event,
                ])
            }
        }
    }

    // MARK: -

    func convertDefaultLogLevelToCustomLogLevel(_ logLevel: DefaultLogLevel) -> SentryLevel {
        switch logLevel {
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .alert:
            return .error
        case .debug:
            return .debug
        }
    }
}
