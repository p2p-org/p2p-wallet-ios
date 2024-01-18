import Foundation

public struct JSONRPCResponseDto<T: Decodable>: Decodable {
    public let id: String?
    public let result: T

    public init(
        id: String,
        result: T
    ) {
        self.id = id
        self.result = result
    }
}

public struct JSONRPCResponseErrorDto<U: Decodable>: Decodable {
    public let id: String?
    public let error: JSONRPCError<U>
}
