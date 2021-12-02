//
//  SendToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

struct SendToken {
    enum NavigatableScene {
        case back
        case chooseTokenAndAmount
        case chooseRecipientAndNetwork
        case confirmation
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
    }
    
    struct Recipient: Hashable {
        let address: String
        let shortAddress: String
        let name: String?
        let hasNoFunds: Bool
    }
    
    enum Network: String {
        case solana, bitcoin
        var icon: UIImage {
            switch self {
            case .solana:
                return .squircleSolanaIcon
            case .bitcoin:
                return .squircleBitcoinIcon
            }
        }
        var defaultFee: Fee {
            switch self {
            case .solana:
                return .init(amount: 0, unit: Defaults.fiat.symbol)
            case .bitcoin:
                return .init(amount: 0.0002, unit: "renBTC")
            }
        }
    }
    
    struct Fee {
        let amount: Double
        let unit: String
    }
}
