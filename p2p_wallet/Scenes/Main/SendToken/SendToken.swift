//
//  SendToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxCocoa

struct SendToken {
    enum NavigatableScene {
        case back
        case chooseTokenAndAmount
        case chooseRecipientAndNetwork
        case confirmation
    }
    
    struct Recipient: Hashable {
        let address: String
        let shortAddress: String
        let name: String?
        let hasNoFunds: Bool
    }
    
    enum Network {
        case solana, bitcoin
        var icon: UIImage {
            switch self {
            case .solana:
                return .squircleSolanaIcon
            case .bitcoin:
                return .squircleBitcoinIcon
            }
        }
    }
    
    struct Fee {
        let amount: Double
        let unit: String
    }
}
