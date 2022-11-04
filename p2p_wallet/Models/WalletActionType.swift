//
//  WalletActionType.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 19.01.2022.
//

import UIKit

enum WalletActionType {
    case receive
    case buy
    case send
    case swap

    var text: String {
        switch self {
        case .receive:
            return L10n.receive
        case .buy:
            return L10n.buy.uppercaseFirst
        case .send:
            return L10n.send
        case .swap:
            return L10n.swap
        }
    }

    var icon: UIImage {
        switch self {
        case .receive:
            return .buttonReceive
        case .buy:
            return .buttonBuy.withTintColor(.h5887ff)
        case .send:
            return .buttonSend
        case .swap:
            return .buttonSwap
        }
    }

    var newIcon: UIImage {
        switch self {
        case .receive:
            return .homeReceive
        case .buy:
            return .homeBuy
        case .send:
            return .homeSend
        case .swap:
            return .homeSwap
        }
    }
}
