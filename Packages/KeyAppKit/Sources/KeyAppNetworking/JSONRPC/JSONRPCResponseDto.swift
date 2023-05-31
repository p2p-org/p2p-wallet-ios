import Foundation

public struct JSONRPCResponseDto<T: Decodable>: Decodable {
    let id: String?
    let result: T
    
    public init(
        id: String,
        result: T
    ) {
        self.id = id
        self.result = result
    }
}

public struct JSONRPCResponseErrorDto: Decodable {
    public let id: String?
    public let error: JSONRPCError?
}

public struct JSONRPCError: Decodable, Error {
    public let code: Int?
}
