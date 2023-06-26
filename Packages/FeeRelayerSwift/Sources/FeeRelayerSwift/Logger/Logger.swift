import Foundation

public enum FeeRelayerSwiftLoggerLogLevel: String {
    case info
    case error
    case warning
    case debug
}

public protocol FeeRelayerSwiftLogger {
    func log(event: String, data: String?, logLevel: FeeRelayerSwiftLoggerLogLevel)
}

public class Logger {

    // MARK: -

    private static var loggers: [FeeRelayerSwiftLogger] = []

    public static func setLoggers(_ loggers: [FeeRelayerSwiftLogger]) {
        self.loggers = loggers
    }

    public static func log(event: String, message: String?, logLevel: FeeRelayerSwiftLoggerLogLevel = .info) {
        loggers.forEach { $0.log(event: event, data: message, logLevel: logLevel) }
    }
}
