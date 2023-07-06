import FeeRelayerSwift
import Foundation
import KeyAppKitLogger
import SolanaSwift
import LoggerSwift

class LoggerSwiftLogger: LogManagerLogger {
    private var queue = DispatchQueue(label: "LoggerSwiftLogger", qos: .utility)

    var supportedLogLevels: [LogLevel] = [.error, .info, .request, .response, .event, .warning, .debug]

    func log(event: String, logLevel: LogLevel, data: String?) {
        queue.async { [unowned self] in
//            LoggerSwift.Logger.log(
//                event: mapEventLogLeverToLoggerSwiftEvent(logLevel),
//                message: event + " " + (data ?? "")
//            )
        }
    }
    
    private func mapEventLogLeverToLoggerSwiftEvent(
        _ event: LogLevel
    ) -> LoggerSwift.LoggerEvent {
        switch event {
        case .info:
            return .info
        case .error:
            return .error
        case .request:
            return .request
        case .response:
            return .response
        case .event:
            return .event
        case .warning:
            return .warning
        case .debug:
            return .debug
        case .alert:
            return .error
        }
    }
}

