import Foundation

public struct JSONRPCRequest<T: Encodable>: Encodable {
    let jsonrpc: String
    let id: String
    let method: String
    let params: T?
    
    public init(
        jsonrpc: String = "2.0",
        id: String = UUID().uuidString,
        method: String,
        params: T? = nil
    ) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.method = method
        self.params = params
    }
}

public extension JSONRPCRequest where T == String { /*T == String, or what ever confirmed to Encodable to fix ambiguous type*/
    /// Non-params initializer
    init(
        jsonrpc: String = "2.0",
        id: String = UUID().uuidString,
        method: String
    ) {
        self.init(
            jsonrpc: jsonrpc,
            id: id,
            method: method,
            params: nil
        )
    }
}
