//
//  Transaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation

struct Transaction: FiatConvertable, ListItemType {
    var id: String { signatureInfo?.signature ?? UUID().uuidString }
    var signatureInfo: SolanaSDK.SignatureInfo?
    var signature: String? {signatureInfo?.signature}
    var slot: UInt64?
    var fee: Double?
    
    var type: TransactionType?
    var from: String?
    var to: String?
    var amount: Double?
    let symbol: String
    var timestamp: Date?
    var status: Status
    var subscription: UInt64?
    var newWallet: Wallet? // new wallet when type == .createAccount
    static func placeholder(at index: Int) -> Transaction {
        Transaction(signatureInfo: SolanaSDK.SignatureInfo(signature: placeholderId(at: index)), type: .createAccount, amount: 10, symbol: "SOL", timestamp: Date(), status: .confirmed)
    }
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
        
        var icon: UIImage {
            switch self {
            case .send:
                return .walletSend
            case .receive:
                return .walletReceive
            case .createAccount:
                return .walletSend
            }
        }
    }
    
    mutating func confirm(by confirmedTransaction: SolanaSDK.TransactionInfo, walletsVM: WalletsVM, myAccountPubkey: SolanaSDK.PublicKey)
    {
        let message = confirmedTransaction.transaction.message
        
        if let instruction = message.instructions.first,
           let dataString = instruction.data
        {
            let bytes = Base58.decode(dataString)
            let wallet = walletsVM.data.first(where: {$0.symbol == symbol})
            
            if bytes.count >= 4 {
                let typeIndex = bytes.toUInt32()
                switch typeIndex {
                case 0:
                    type = .createAccount
                case 2:
                    if message.accountKeys.first?.publicKey == myAccountPubkey {
                        type = .send
                    } else {
                        type = .receive
                    }
                default:
                    break
                }
                
            }
            
            slot = confirmedTransaction.slot
            
            if message.accountKeys.count >= 2 {
                from = message.accountKeys[0].publicKey.base58EncodedString
                to = message.accountKeys[1].publicKey.base58EncodedString
            }
            
            if bytes.count >= 12, let lamport = Array(bytes[4..<12]).toUInt64() {
                var decimals = wallet?.decimals ?? 0
                if type == .createAccount {
                    decimals = 9
                }
                
                amount = Double(lamport) * pow(Double(10), -(Double(decimals)))
                fee = Double(confirmedTransaction.meta?.fee ?? 0) * pow(Double(10), -(Double(decimals)))
                
                if [Transaction.TransactionType.send, Transaction.TransactionType.createAccount].contains(type) {amount = -amount!}
            }
        }
    }
}
