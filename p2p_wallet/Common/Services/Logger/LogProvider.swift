import Foundation

protocol LogProvider {
    associatedtype CustomLogLevel
    var supportedLogLevels: [LogLevel] { get set }
    func log(event: String, logLevel: LogLevel, data: String?)
    func convertLogLevelToCustomLogLevel(_ logLevel: LogLevel) -> CustomLogLevel
}
