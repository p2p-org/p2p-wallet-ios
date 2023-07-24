import Foundation

class DefaultLogManager {
    // MARK: - Properties

    /// The sensitive data filter used to filter sensitive information from logs.
    let dataFilter = DefaultSensitiveDataFilter()

    /// The array of log providers to which the log messages will be sent.
    private(set) var providers: [any LogProvider] = []

    /// The dispatch queue used to asynchronously process log messages.
    private var queue = DispatchQueue(label: "DefaultLogManager", qos: .utility, attributes: [.concurrent])

    // MARK: - Public Methods

    /// Sets the log providers to be used for logging.
    /// - Parameter providers: An array of log providers.
    func setProviders(_ providers: [any LogProvider]) {
        self.providers = providers
    }

    /// Logs a message with the specified event and log level to all registered log providers.
    /// - Parameters:
    ///   - event: The event or description of the log message.
    ///   - logLevel: The log level of the message (e.g., error, warning, info, debug).
    ///   - data: Optional data associated with the log message (e.g., additional context).
    func log(event: String, logLevel: LogLevel, data: String? = nil) {
        providers.forEach { provider in
            guard provider.supportedLogLevels.contains(logLevel) else { return }
            queue.async {
                provider.log(event: event, logLevel: logLevel, data: self.dataFilter.map(string: data ?? ""))
            }
        }
    }

    /// Logs a message with the specified event and log level, along with structured data.
    /// - Parameters:
    ///   - event: The event or description of the log message.
    ///   - logLevel: The log level of the message (e.g., error, warning, info, debug).
    ///   - data: Optional structured data associated with the log message.
    func log(event: String, logLevel: LogLevel, data: (any Encodable)?) {
        log(event: event, logLevel: logLevel, data: data?.jsonString)
    }

    /// Logs an error message.
    /// - Parameter error: The error object to be logged.
    func log(error: Error) {
        // Capture error information
        if let error = error as? CustomNSError {
            log(event: "Error", logLevel: .error, data: error.errorUserInfo[NSDebugDescriptionErrorKey] as? String)
        }
        // Log non-custom errors
        else {
            log(event: "Error", logLevel: .error, data: String(reflecting: error))
        }
    }
}
