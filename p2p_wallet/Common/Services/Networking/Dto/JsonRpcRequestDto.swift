import Foundation

struct JsonRpcRequestDto<T: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let id = UUID().uuidString
    let method: String
    let params: [T]
}
