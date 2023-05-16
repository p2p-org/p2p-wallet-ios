import Foundation
import SolanaSwift
import FeeRelayerSwift
import KeyAppKitLogger

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

protocol LogManager {
    func setProviders(_ providers: [LogManagerLogger])
    func log(event: String, logLevel: LogLevel, data: String?, shouldLogEvent: (() -> Bool)?)
    func log(event: String, logLevel: LogLevel, data: (any Encodable)?)
}

class DefaultLogManager: LogManager {
    static let shared = DefaultLogManager()
    let dataFilter = DefaultSensitiveDataFilter()

    private(set) var providers: [LogManagerLogger] = []
    private var queue = DispatchQueue(label: "DefaultLogManager", qos: .utility, attributes: [.concurrent])

    func setProviders(_ providers: [LogManagerLogger] = [SentryLogger(), AlertLogger()]) {
        self.providers = providers
    }

    func log(event: String, logLevel: LogLevel, data: String? = nil, shouldLogEvent: (() -> Bool)? = nil) {
        guard shouldLogEvent?() ?? true else { return }
        providers.forEach { provider in
            queue.async {
                provider.log(event: event, logLevel: logLevel, data: self.dataFilter.map(string: data ?? ""))
            }
        }
    }

    func log(event: String, logLevel: LogLevel, data: (any Encodable)?) {
        log(event: event, logLevel: logLevel, data: data?.jsonString, shouldLogEvent: nil)
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
            newLogLevel = .error
        }
        
        self.providers.forEach { logger in
            guard logger.supportedLogLevels.contains(newLogLevel) else { return }
            log(event: event, logLevel: newLogLevel, data: data)
        }
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

protocol SensitiveDataFilterRule {
    func map(_ string: String) -> String
}

protocol SensitiveDataFilter {
    var rules: [SensitiveDataFilterRule] { get }
    func map(string: String) -> String
    func map(data: [AnyHashable: AnyHashable]) -> [AnyHashable: AnyHashable]
}

struct PrivateKeySensitiveDataFilterRule: SensitiveDataFilterRule {
    let placeholder = "<SensitiveDataFilter>"
    let regs = ["[1-9A-HJ-NP-Za-km-z]{87}", "0x[a-fA-F0-9]{64}"]

    func map(_ string: String) -> String {
        var str = string
        regs.forEach { reg in
            guard let regex = try? NSRegularExpression(pattern: reg, options: NSRegularExpression.Options.caseInsensitive) else {
                return
            }
            let range = NSMakeRange(0, string.count)
            let modString = regex.stringByReplacingMatches(
                in: string, options: [], range: range, withTemplate: placeholder
            )
            str = modString
        }
        return str
    }
}

class DefaultSensitiveDataFilter: SensitiveDataFilter {
    var rules: [SensitiveDataFilterRule] = [PrivateKeySensitiveDataFilterRule()]

    func map(string: String) -> String {
        var ret = string
        rules.forEach { rule in
            ret = rule.map(ret)
        }
        return ret
    }

    func map(data: [AnyHashable: AnyHashable]) -> [AnyHashable: AnyHashable] {
        var newData = data
        data.keys.forEach { key in
            if let value = data[key] as? String {
                newData[key] = self.map(string: value)
            }
        }
        return newData
    }
}
