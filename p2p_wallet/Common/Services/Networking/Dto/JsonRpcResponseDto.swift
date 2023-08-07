import Foundation

struct JsonRpcResponseDto<T: Decodable>: Decodable {
    let id: String
    let result: T
}

struct JsonRpcResponseErrorDto: Decodable {
    let id: String
    let error: JsonRpcError
}

struct JsonRpcError: Decodable, Error {
    let code: Int
}
