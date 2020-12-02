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
    
    init?(symbol: String, confirmedTransaction: SolanaSDK.Transaction.Info?, signatureInfo: SolanaSDK.Transaction.SignatureInfo?, timestamp: Date?) {
        
        var type: ActivityType?
        var amount: Double?
        var tokens: Double?
        
        if let confirmedTransaction = confirmedTransaction {
            let message = confirmedTransaction.transaction.message
            
            if let instruction = message.instructions.first,
               let dataString = instruction.data
            {
                let bytes = Base58.decode(dataString)
                let wallet = WalletsVM.ofCurrentUser.data.first(where: {$0.symbol == symbol})
                
                if bytes.count >= 4 {
                    let typeIndex = bytes.toUInt32()
                    switch typeIndex {
                    case 0:
                        type = .createAccount
                    case 2:
                        if message.accountKeys.first?.publicKey == SolanaSDK.shared.accountStorage.account?.publicKey {
                            type = .send
                        } else {
                            type = .receive
                        }
                    default:
                        break
                    }
                    
                }
                if bytes.count >= 12, let lamport = Array(bytes[4..<12]).toUInt64() {
                    tokens = Double(lamport) * pow(Double(10), -(Double(wallet?.decimals ?? 0)))
                    
                    if [ActivityType.send, ActivityType.createAccount].contains(type) {tokens = -tokens!}
                    
                    let price = PricesManager.bonfida.prices.value.first(where: {$0.from == symbol})
                    amount = tokens * price?.value
                }
            }
        }
        
        if confirmedTransaction == nil, signatureInfo == nil, timestamp == nil {
            return nil
        }
        
        self.init(type: type, amount: amount, tokens: tokens, symbol: symbol, timestamp: timestamp, info: signatureInfo)
    }
}

extension Activity: ListItemType {
    static func placeholder(at index: Int) -> Activity {
        Activity(type: .receive, amount: 0.12, tokens: 0.12, symbol: "SOL#\(index)", timestamp: Date(), info: nil)
    }
}
