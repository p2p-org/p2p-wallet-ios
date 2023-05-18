import Foundation

// TODO: - Move to KeyAppKit later!!!

/// Service that monitors all swap errors
public protocol SwapErrorLogger: AnyObject {
    /// Send error detail to server
    /// - Parameter detail: detail of the error
    func logErrorDetail(_ info: SwapErrorDetail) async throws
}

/// Default implementation of `SwapErrorLogger`
public final class SwapErrorLoggerImpl: SwapErrorLogger {
    
    // MARK: - Properties

    /// Endpoint to send error to
    private let endpoint: URL

    // MARK: - Initializer

    public init(endpoint: URL) {
        self.endpoint = endpoint
    }
    
    // MARK: - Methods

    /// Send error detail to server
    /// - Parameter detail: detail of the error
    public func logErrorDetail(_ info: SwapErrorDetail) async throws {
        // send request to endpoint
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(info)
        
        try Task.checkCancellation()
        
        let (_, response) = try await URLSession.shared.data(from: urlRequest)
        
        try Task.checkCancellation()
        
        guard let code = (response as? HTTPURLResponse)?.statusCode,
                (200...299).contains(code)
        else {
            throw SwapErrorLoggerError.invalidStatusCode
        }
    }
}
