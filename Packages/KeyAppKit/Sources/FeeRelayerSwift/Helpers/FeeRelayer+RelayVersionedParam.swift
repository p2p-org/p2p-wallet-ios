//
//  File.swift
//
//
//  Created by Giang Long Tran on 02.04.2023.
//

import Foundation
import SolanaSwift

public struct SignRelayTransactionParam: Codable {
    let transaction: VersionedTransaction
    let statsInfo: StatsInfo

    enum CodingKeys: String, CodingKey {
        case transaction
        case statsInfo = "info"
    }

    public init(
        transaction: VersionedTransaction,
        statsInfo: StatsInfo
    ) throws {
        self.transaction = transaction
        self.statsInfo = statsInfo
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let serializedTransaction = try transaction.serialize()
        let base64Transaction = serializedTransaction.base64EncodedString()

        try container.encode(base64Transaction, forKey: .transaction)
        try container.encode(statsInfo, forKey: .statsInfo)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let base64Transaction = try container.decode(String.self, forKey: .transaction)
        let serializedTransaction = Data(base64Encoded: base64Transaction) ?? Data()

        transaction = try VersionedTransaction.deserialize(data: serializedTransaction)

        statsInfo = try container.decode(StatsInfo.self, forKey: .statsInfo)
    }
}
