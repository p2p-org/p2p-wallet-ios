import Foundation

public struct ProxyConfiguration {
    public let address: String
    public let port: Int?

    public init(address: String, port: Int?) {
        self.address = address
        self.port = port
    }
}
