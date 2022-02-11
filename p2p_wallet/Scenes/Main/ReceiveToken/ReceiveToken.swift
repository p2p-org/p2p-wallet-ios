//
//  ReceiveToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import UIKit

enum ReceiveToken {
    enum NavigatableScene {
        case showInExplorer(address: String)
        case showBTCExplorer(address: String)
        case showRenBTCReceivingStatus
        case share(address: String? = nil, qrCode: UIImage? = nil)
        case networkSelection
        case showSupportedTokens
        case showRentBTCConfirm(onCompletion: BEVoidCallback)
        case showRentBTCTopUpAccount(onCompletion: BEVoidCallback)
        case showRentBTCCreateAccount(onCompletion: BEVoidCallback)
        case help
    }
    
    enum TokenType: CaseIterable {
        case solana, btc
        
        var icon: UIImage {
            switch self {
            case .btc:
                return .squircleBitcoinIcon
            case .solana:
                return .squircleSolanaIcon
            }
        }
        
        var localizedName: String {
            switch self {
            case .solana:
                return L10n.solana
            case .btc:
                return L10n.bitcoin
            }
        }
    }
}
