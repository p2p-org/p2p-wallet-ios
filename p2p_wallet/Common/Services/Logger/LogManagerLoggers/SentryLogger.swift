import FeeRelayerSwift
import Foundation
import KeyAppKitLogger
import Sentry
import SolanaSwift

class SentryLogger: LogManagerLogger {
    private var queue = DispatchQueue(label: "SentryLogger", qos: .utility)

    var supportedLogLevels: [LogLevel] = [.error, .alert]

    func log(event: String, logLevel: LogLevel, data: String?) {
        guard supportedLogLevels.contains(logLevel) else { return }
        queue.sync {
            let sentryEvent = Event(level: sentryLevel(logLevel: logLevel))
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

    private func sentryLevel(logLevel: LogLevel) -> SentryLevel {
        switch logLevel {
        case .info:
            return SentryLevel.info
        case .error:
            return SentryLevel.error
        case .alert:
            return SentryLevel.error
        case .request, .response:
            return SentryLevel.info
        case .event:
            return SentryLevel.info
        case .warning:
            return SentryLevel.warning
        case .debug:
            return SentryLevel.debug
        }
    }
}
