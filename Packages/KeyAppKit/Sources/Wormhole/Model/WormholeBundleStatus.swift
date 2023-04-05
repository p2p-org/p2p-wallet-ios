//
//  File.swift
//
//
//  Created by Giang Long Tran on 05.04.2023.
//

import Foundation

public struct WormholeBundleStatus: Codable, Hashable {
    public let bundleId: String
    public let userWallet: String
    public let recipient: String
    public let resultAmount: TokenAmount
    public let fees: ClaimFees?
    public let status: Status

    enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
        case userWallet = "user_wallet"
        case recipient
        case resultAmount = "result_amount"
        case fees
        case status
    }

    public enum Status: String, Codable, Hashable {
        case failed
        case pending
        case expired
        case canceled
        case inProgress = "in_progress"
        case completed
    }
}
