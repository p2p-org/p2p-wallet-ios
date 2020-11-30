//
//  Activity.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2020.
//

import Foundation

struct Activity {
    let type: ActivityType?
    let amount: Double?
    let tokens: Double?
    let symbol: String
    let timestamp: Date?
    let info: SolanaSDK.Transaction.SignatureInfo?
}

extension Activity {
    enum ActivityType: String {
        case send, receive, createAccount
        var localizedString: String {
            switch self {
            case .send:
                return L10n.sendTokens
            case .receive:
                return L10n.receiveTokens
            case .createAccount:
                return L10n.addCoin
            }
        }
    }
}

extension Activity: ListItemType {
    static func placeholder(at index: Int) -> Activity {
        Activity(type: .receive, amount: 0.12, tokens: 0.12, symbol: "SOL#\(index)", timestamp: Date(), info: nil)
    }
}
