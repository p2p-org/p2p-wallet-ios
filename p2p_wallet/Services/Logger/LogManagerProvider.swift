import FeeRelayerSwift
import Foundation
import KeyAppKitLogger
import Sentry
import SolanaSwift

class SentryLogger: LogManagerLogger {
    private var queue = DispatchQueue(label: "SentryLogger", qos: .utility)

    var supportedLogLevels: [LogLevel] = [.error]

    func log(event: String, logLevel: LogLevel, data: String?) {
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
            return SentryLevel.fatal
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

extension SentryLogger: SolanaSwiftLogger {
    func log(event: String, data: String?, logLevel: SolanaSwiftLoggerLogLevel) {
        var newLogLevel: LogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        }

        guard supportedLogLevels.contains(newLogLevel) else { return }

        log(event: event, logLevel: newLogLevel, data: data)
    }
}

extension SentryLogger: FeeRelayerSwiftLogger {
    func log(event: String, data: String?, logLevel: FeeRelayerSwiftLoggerLogLevel) {
        var newLogLevel: LogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        }

        guard supportedLogLevels.contains(newLogLevel) else { return }

        log(event: event, logLevel: newLogLevel, data: data)
    }
}

extension SentryLogger: KeyAppKitLoggerType {
    func log(event: String, data: String?, logLevel: KeyAppKitLoggerLogLevel) {
        var newLogLevel: LogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        }

        guard supportedLogLevels.contains(newLogLevel) else { return }

        log(event: event, logLevel: newLogLevel, data: data)
    }
}

class LoggerSwiftLogger: LogManagerLogger {
    private var queue = DispatchQueue(label: "LoggerSwiftLogger", qos: .utility)

    var supportedLogLevels: [LogLevel] = [.error, .info, .request, .response, .event, .warning, .debug]

    func log(event: String, logLevel: LogLevel, data: String?) {
        queue.sync {
            KeyAppKitLogger.Logger.log(
                event: loglevel(logLevel),
                message: event + " " + (data ?? "")
            )
        }
    }

    // MARK: -

    private func loglevel(_ logLevel: LogLevel) -> String {
        switch logLevel {
        case .info:
            return KeyAppKitLoggerLogLevel.info.rawValue
        case .error:
            return KeyAppKitLoggerLogLevel.error.rawValue
        case .request, .response:
            return KeyAppKitLoggerLogLevel.info.rawValue
        case .event:
            return KeyAppKitLoggerLogLevel.info.rawValue
        case .warning:
            return KeyAppKitLoggerLogLevel.warning.rawValue
        case .debug:
            return KeyAppKitLoggerLogLevel.debug.rawValue
        }
    }
}

extension LoggerSwiftLogger: SolanaSwiftLogger {
    func log(event: String, data: String?, logLevel: SolanaSwiftLoggerLogLevel) {
        var newLogLevel: LogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        }

        guard supportedLogLevels.contains(newLogLevel) else { return }

        log(event: event, logLevel: newLogLevel, data: data)
    }
}

extension LoggerSwiftLogger: FeeRelayerSwiftLogger {
    func log(event: String, data: String?, logLevel: FeeRelayerSwiftLoggerLogLevel) {
        var newLogLevel: LogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        }

        guard supportedLogLevels.contains(newLogLevel) else { return }

        log(event: event, logLevel: newLogLevel, data: data)
    }
}

extension LoggerSwiftLogger: KeyAppKitLoggerType {
    func log(event: String, data: String?, logLevel: KeyAppKitLoggerLogLevel) {
        var newLogLevel: LogLevel = .info
        switch logLevel {
        case .info:
            newLogLevel = .info
        case .error:
            newLogLevel = .error
        case .warning:
            newLogLevel = .warning
        case .debug:
            newLogLevel = .debug
        }

        guard supportedLogLevels.contains(newLogLevel) else { return }

        log(event: event, logLevel: newLogLevel, data: data)
    }
}
