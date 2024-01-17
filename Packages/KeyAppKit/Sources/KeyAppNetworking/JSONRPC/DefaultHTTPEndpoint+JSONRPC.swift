import Foundation

/// Public extension for HTTPClient for handy use of DefaultHTTPEndpoint
public extension DefaultHTTPEndpoint {
    init<P: Encodable>(
        baseURL: String,
        path: String,
        method: HTTPMethod,
        header: [String: String],
        body: JSONRPCRequestDto<P>
    ) throws {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.header = header
        self.body = try String(
            data: JSONEncoder().encode(body),
            encoding: .utf8
        )
    }
}
