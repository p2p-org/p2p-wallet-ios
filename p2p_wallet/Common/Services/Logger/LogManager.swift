import AnalyticsManager
import FeeRelayerSwift
import Foundation
import KeyAppKitLogger
import SolanaSwift

enum LogLevel: String {
    case info
    case error
    case request
    case response
    case event
    case warning
    case debug
    case alert
}

protocol LogManagerLogger {
    var supportedLogLevels: [LogLevel] { get set }
    func log(event: String, logLevel: LogLevel, data: String?)
}

class DefaultLogManager {
    static let shared: DefaultLogManager = {
        let manager = DefaultLogManager()
        SolanaSwift.Logger.setLoggers([manager])
        FeeRelayerSwift.Logger.setLoggers([manager])
        KeyAppKitLogger.Logger.setLoggers([manager])
        return manager
    }()

    let dataFilter = DefaultSensitiveDataFilter()

    private(set) var providers: [LogManagerLogger] = []
    private var queue = DispatchQueue(label: "DefaultLogManager", qos: .utility, attributes: [.concurrent])

    func setProviders(_ providers: [LogManagerLogger] = [SentryLogger(), AlertLogger()]) {
        self.providers = providers
    }

    func log(event: String, logLevel: LogLevel, data: String? = nil) {
        providers.forEach { provider in
            guard provider.supportedLogLevels.contains(logLevel) else { return }
            queue.async {
                provider.log(event: event, logLevel: logLevel, data: self.dataFilter.map(string: data ?? ""))
            }
        }
    }

    func log(event: String, logLevel: LogLevel, data: (any Encodable)?) {
        log(event: event, logLevel: logLevel, data: data?.jsonString)
    }
}

extension DefaultLogManager: SolanaSwiftLogger, FeeRelayerSwiftLogger, KeyAppKitLoggerType {
    func log(event: String, data: String?, logLevel: LogLevel) {
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
        case .request:
            newLogLevel = .request
        case .response:
            newLogLevel = .response
        case .event:
            newLogLevel = .event
        case .alert:
            newLogLevel = .alert
        }

        log(event: event, logLevel: newLogLevel, data: data)
    }

    func log(event: String, data: String?, logLevel: SolanaSwift.SolanaSwiftLoggerLogLevel) {
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

        log(event: event, data: data, logLevel: newLogLevel)
    }

    func log(event: String, data: String?, logLevel: FeeRelayerSwift.FeeRelayerSwiftLoggerLogLevel) {
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
        log(event: event, data: data, logLevel: newLogLevel)
    }

    func log(event: String, data: String?, logLevel: KeyAppKitLogger.KeyAppKitLoggerLogLevel) {
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
        log(event: event, data: data, logLevel: newLogLevel)
    }
}
