import FeeRelayerSwift
import Foundation
import KeyAppKitLogger
import SolanaSwift

// MARK: - Singleton

extension DefaultLogManager {
    static let shared: DefaultLogManager = {
        let manager = DefaultLogManager()
        SolanaSwift.Logger.setLoggers([manager])
        FeeRelayerSwift.Logger.setLoggers([manager])
        KeyAppKitLogger.Logger.setLoggers([manager])
        return manager
    }()
}

// MARK: - DefaultLogLevelConvertible

protocol DefaultLogLevelConvertible {
    func convertToDefaultLogLevel() -> DefaultLogLevel
}

extension SolanaSwiftLoggerLogLevel: DefaultLogLevelConvertible {
    func convertToDefaultLogLevel() -> DefaultLogLevel {
        switch self {
        case .info:
            return .info
        case .error:
            return .error
        case .warning:
            return .warning
        case .debug:
            return .debug
        }
    }
}

extension FeeRelayerSwiftLoggerLogLevel: DefaultLogLevelConvertible {
    func convertToDefaultLogLevel() -> DefaultLogLevel {
        switch self {
        case .info:
            return .info
        case .error:
            return .error
        case .warning:
            return .warning
        case .debug:
            return .debug
        }
    }
}

extension KeyAppKitLoggerLogLevel: DefaultLogLevelConvertible {
    func convertToDefaultLogLevel() -> DefaultLogLevel {
        switch self {
        case .info:
            return .info
        case .error:
            return .error
        case .warning:
            return .warning
        case .debug:
            return .debug
        }
    }
}

extension DefaultLogManager: SolanaSwiftLogger,
    FeeRelayerSwiftLogger,
    KeyAppKitLoggerType
{
    func log(event: String, data: String?, logLevel: SolanaSwift.SolanaSwiftLoggerLogLevel) {
        log(event: event, logLevel: logLevel.convertToDefaultLogLevel(), data: data)
    }

    func log(event: String, data: String?, logLevel: FeeRelayerSwift.FeeRelayerSwiftLoggerLogLevel) {
        log(event: event, logLevel: logLevel.convertToDefaultLogLevel(), data: data)
    }

    func log(event: String, data: String?, logLevel: KeyAppKitLogger.KeyAppKitLoggerLogLevel) {
        log(event: event, logLevel: logLevel.convertToDefaultLogLevel(), data: data)
    }
}
