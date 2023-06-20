import Foundation

/// A mock implementation of `HTTPURLSession` for testing or mocking purposes.
public class MockURLSession: HTTPURLSession {
    private let responseString: String?
    private let statusCode: Int
    private let mockError: Error?
    
    /// Initializes a new instance of `MockURLSession`.
    ///
    /// - Parameters:
    ///   - responseString: The response string to be returned by the data task.
    ///   - statusCode: The HTTP status code of the mock response. Defaults to 200.
    ///   - error: The error to be thrown by the data task. Defaults to nil.
    public init(responseString: String?, statusCode: Int = 200, error: Error? = nil) {
        self.responseString = responseString
        self.statusCode = statusCode
        self.mockError = error
    }
    
    /// Simulates fetching data for the given URL request.
    ///
    /// - Parameter urlRequest: The URL request for which to fetch the data.
    /// - Returns: A tuple containing the response data and URL response.
    /// - Throws: An error if the mock error is set or if the response string is nil.
    public func data(for urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let responseString = responseString else {
            throw HTTPClientError.invalidResponse(nil, Data())
        }
        
        let url = urlRequest.url!
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let data = responseString.data(using: .utf8)!
        
        return (data, response)
    }
}
