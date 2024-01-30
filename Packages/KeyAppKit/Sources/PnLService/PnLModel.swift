import Foundation

public protocol PnLModel {
    var total: RPCPnLResponseDetail? { get }
    var pnlByMint: [String: RPCPnLResponseDetail] { get }
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
