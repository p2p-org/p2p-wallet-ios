//
//  SendToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa
import SolanaSwift

enum SendToken {
    enum NavigatableScene {
        case back
        case chooseTokenAndAmount(showAfterConfirmation: Bool)
        
        case chooseRecipientAndNetwork(showAfterConfirmation: Bool, preSelectedNetwork: Network?)
        case chooseNetwork
        
        case confirmation
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
    }
    
    struct Recipient: Hashable {
        init(address: String, name: String?, hasNoFunds: Bool, hasNoInfo: Bool = false) {
            self.address = address
            self.name = name
            self.hasNoFunds = hasNoFunds
            self.hasNoInfo = hasNoInfo
        }
        
        let address: String
        let name: String?
        let hasNoFunds: Bool
        let hasNoInfo: Bool
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
    }
    
    struct FeeInfo {
        let wallet: Wallet?
        let feeAmount: SolanaSDK.FeeAmount
        let feeAmountInSOL: SolanaSDK.FeeAmount
        
        static var empty: Self {
            .init(wallet: nil, feeAmount: .zero, feeAmountInSOL: .zero)
        }
        
        var isValid: Bool {
            if let wallet = wallet {
                return (wallet.lamports ?? 0) >= feeAmount.total
            } else {
                return feeAmount.total == 0
            }
        }
    }
}
