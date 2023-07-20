import Foundation

public struct StrigaGetAccountStatementResponse: Codable {
    public let transactions: [Transaction]

    public struct Transaction: Codable {
        let id: String
        let txType: String
        let bankingSenderBic: String?
        let bankingSenderIban: String?
    }
}
