//
//  ReceiveToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation

struct ReceiveToken {
    enum NavigatableScene {
        case showInExplorer(address: String)
        case showBTCExplorer(address: String)
        case chooseBTCOption(selectedOption: BTCTypeOption)
        case showRenBTCReceivingStatus
        case share(address: String? = nil, qrCode: UIImage? = nil)
        case help
    }
    
    enum TokenType: CaseIterable {
        case solana, btc
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
