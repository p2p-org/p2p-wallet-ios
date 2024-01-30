import Foundation
import KeyAppNetworking

public protocol PnLService {
    associatedtype PnL: PnLModel
    func getPNL(userWallet: String, mints: [String]) async throws -> PnL
}

extension Dictionary: PnLModel where Key == String, Value == RPCPnLResponseDetail {
    public var total: RPCPnLResponseDetail? {
        self["total"]
    }

    public var pnlByMint: [String: RPCPnLResponseDetail] {
        var dict = self
        dict.removeValue(forKey: "total")
        return dict
    }
}

public class PnLServiceImpl: PnLService {
    private let urlSession: HTTPURLSession

    public init(urlSession: HTTPURLSession = URLSession.shared) {
        self.urlSession = urlSession
    }

    public func getPNL(userWallet: String, mints: [String]) async throws -> [String: RPCPnLResponseDetail] {
        struct PnLRPCRequest: Codable {
            let userWallet: String
            let mints: [String]

            enum CodingKeys: String, CodingKey {
                case userWallet = "user_wallet"
                case mints
            }
        }

        return try await JSONRPCHTTPClient(urlSession: urlSession)
            .request(
                baseURL: "https://pnl.key.app",
                body: .init(
                    method: "get_pnl",
                    params: PnLRPCRequest(
                        userWallet: userWallet,
                        mints: mints
                    )
                )
            )
    }
}
