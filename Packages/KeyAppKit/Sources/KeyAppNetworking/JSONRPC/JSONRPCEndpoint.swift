import Foundation

struct JSONRPCEndpoint<Body: Encodable>: HTTPEndpoint {
    let baseURL: String
    let path: String = ""
    let method: HTTPMethod
    let header: [String : String]
    let body: JSONRPCRequest<Body>?
    let responseDecoder: JSONRPCResponseDecoder
}
