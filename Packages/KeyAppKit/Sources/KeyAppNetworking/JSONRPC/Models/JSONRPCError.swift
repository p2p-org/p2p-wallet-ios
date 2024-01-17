import Foundation

public struct JSONRPCError<U: Decodable>: Decodable, Error, LocalizedError {
    public let code: Int?
    public let message: String?
    public let data: U?

    public init(code: Int, message: String, data: U?) {
        self.code = code
        self.message = message
        self.data = data
    }

    public var errorDescription: String? {
        "Code \(code ?? -1). Reason: \(message ?? "Unknown")"
    }
}

public extension JSONRPCError where U == String {
    init(code: Int, message: String) {
        self.code = code
        self.message = message
        data = nil
    }
}
