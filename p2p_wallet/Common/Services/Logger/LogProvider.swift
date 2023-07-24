import Foundation

protocol LogProvider {
    associatedtype CustomLogLevel
    var supportedLogLevels: [DefaultLogLevel] { get set }
    func log(event: String, logLevel: DefaultLogLevel, data: String?)
    func convertDefaultLogLevelToCustomLogLevel(_ logLevel: DefaultLogLevel) -> CustomLogLevel
}
