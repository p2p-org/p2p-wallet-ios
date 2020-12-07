//
//  Activity.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2020.
//

import Foundation

struct Activity {
    var id: String { transaction.id }
    var transaction: Transaction
}

extension Activity {
    mutating func withConfirmedTransaction(_ confirmedTransaction: SolanaSDK.Transaction.Info)
    {
        let message = confirmedTransaction.transaction.message
        
        if let instruction = message.instructions.first,
           let dataString = instruction.data
        {
            let bytes = Base58.decode(dataString)
            let wallet = WalletsVM.ofCurrentUser.data.first(where: {$0.symbol == transaction.symbol})
            
            if bytes.count >= 4 {
                let typeIndex = bytes.toUInt32()
                switch typeIndex {
                case 0:
                    transaction.type = .createAccount
                case 2:
                    if message.accountKeys.first?.publicKey == SolanaSDK.shared.accountStorage.account?.publicKey {
                        transaction.type = .send
                    } else {
                        transaction.type = .receive
                    }
                default:
                    break
                }
                
            }
            
            transaction.slot = confirmedTransaction.slot
            
            if message.accountKeys.count >= 2 {
                transaction.from = message.accountKeys[0].publicKey.base58EncodedString
                transaction.to = message.accountKeys[1].publicKey.base58EncodedString
            }
            
            if bytes.count >= 12, let lamport = Array(bytes[4..<12]).toUInt64() {
                var decimals = wallet?.decimals ?? 0
                if transaction.type == .createAccount {
                    decimals = 9
                }
                
                transaction.amount = Double(lamport) * pow(Double(10), -(Double(decimals)))
                transaction.fee = Double(confirmedTransaction.meta?.fee ?? 0) * pow(Double(10), -(Double(decimals)))
                
                if [Transaction.TransactionType.send, Transaction.TransactionType.createAccount].contains(transaction.type) {transaction.amount = -transaction.amount!}
            }
        }
    }
}

extension Activity: ListItemType {
    static func placeholder(at index: Int) -> Activity {
        Activity(transaction: Transaction(signatureInfo: .init(signature: placeholderId(at: index)), type: .createAccount, amount: Double(index), symbol: "SOL", timestamp: Date(), status: .confirmed))
    }
}
