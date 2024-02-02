import Foundation

public protocol PnLModel {
    var total: RPCPnLResponseDetail? { get }
    var pnlByMint: [String: RPCPnLResponseDetail] { get }
}

struct PnLRPCRequest: Codable {
    let userWallet: String
    let mints: [String]

    enum CodingKeys: String, CodingKey {
        case userWallet = "user_wallet"
        case mints
    }
}

public struct RPCPnLResponseDetail: Codable {
    public let usdAmount, percent: String

    public init(usdAmount: String, percent: String) {
        self.usdAmount = usdAmount
        self.percent = percent
    }

    enum CodingKeys: String, CodingKey {
        case usdAmount = "usd_amount"
        case percent
    }
}
