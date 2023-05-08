//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.04.2023.
//

import Foundation

public struct WormholeSendStatus: Codable, Equatable {
    public let id: String

    public let status: WormholeStatus

    public let userWallet: String

    public let recipient: String

    public let amount: TokenAmount

    public let fees: SendFees

    public let created: Date

    public let modified: Date

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case userWallet = "user_wallet"
        case recipient
        case amount
        case fees
        case created
        case modified
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        status = try container.decode(WormholeStatus.self, forKey: .status)
        userWallet = try container.decode(String.self, forKey: .userWallet)
        recipient = try container.decode(String.self, forKey: .recipient)
        amount = try container.decode(TokenAmount.self, forKey: .amount)
        fees = try container.decode(SendFees.self, forKey: .fees)
        created = try container.decode(Date.self, forKey: .created)
        modified = try container.decode(Date.self, forKey: .modified)
    }
}
