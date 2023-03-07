import Foundation

public enum KeyAppKitLoggerLogLevel: String {
    case info
    case error
    case warning
    case debug
}

public protocol KeyAppKitLoggerType {
    func log(event: String, data: String?, logLevel: KeyAppKitLoggerLogLevel)
}

public class Logger {
    
    private static var loggers: [KeyAppKitLoggerType] = []
    
    // MARK: -
    
    public static func setLoggers(_ loggers: [KeyAppKitLoggerType]) {
        self.loggers = loggers
    }
    
    public static func log(event: String, message: String?, logLevel: KeyAppKitLoggerLogLevel = .info) {
        loggers.forEach { $0.log(event: event, data: message, logLevel: logLevel) }
    }

}
