//
//  Transaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation

struct Transaction {
    var id: String { signatureInfo?.signature ?? UUID().uuidString }
    var signatureInfo: SolanaSDK.SignatureInfo?
    var signature: String? {signatureInfo?.signature}
    var slot: UInt64?
    var fee: Double?
    
    var from: String?
    var to: String?
    var amount: Double?
    let symbol: String
    var timestamp: Date?
    var status: Status
    var subscription: UInt64?
    var newWallet: Wallet? // new wallet when type == .createAccount
}

extension Transaction {
    enum Status {
        case processing, confirmed
        var localizedString: String {
            switch self {
            case .processing:
                return L10n.processing
            case .confirmed:
                return L10n.confirmed
            }
        }
    }
}
