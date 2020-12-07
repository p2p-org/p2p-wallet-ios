//
//  Transaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation

struct Transaction: Hashable, FiatConvertable {
    var id: String { signatureInfo?.signature ?? UUID().uuidString }
    let signatureInfo: SolanaSDK.Transaction.SignatureInfo?
    var signature: String? {signatureInfo?.signature}
    
    var type: TransactionType?
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
    
    enum TransactionType: String {
        case send, receive, createAccount
        var localizedString: String {
            switch self {
            case .send:
                return L10n.sendTokens
            case .receive:
                return L10n.receiveTokens
            case .createAccount:
                return L10n.addWallet
            }
        }
    }
}
