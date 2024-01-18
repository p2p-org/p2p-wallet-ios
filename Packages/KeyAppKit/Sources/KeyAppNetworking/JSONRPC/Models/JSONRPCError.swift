import Foundation

public struct JSONRPCError<DataType: Decodable>: Decodable, Error, LocalizedError {
    public let code: Int?
    public let message: String?
    public let data: DataType?

    public init(code: Int, message: String, data: DataType?) {
        self.code = code
        self.message = message
        self.data = data
    }

    public var errorDescription: String? {
        "Code \(code ?? -1). Reason: \(message ?? "Unknown")"
    }
}

public extension JSONRPCError where DataType == EmptyData {
    init(code: Int, message: String) {
        self.code = code
        self.message = message
        data = nil
    }
}
