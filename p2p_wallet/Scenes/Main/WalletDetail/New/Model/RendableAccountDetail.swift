//
//  RendableAccountDetail.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Foundation

protocol RendableAccountDetail {
    var amountInToken: String { get }
    var amountInFiat: String { get }

    var actions: [RendableAccountDetailAction] { get }
    var onAction: (RendableAccountDetailAction) -> Void { get }
}

enum RendableAccountDetailAction: Int, Identifiable {
    var id: Int { rawValue }

    case buy
    case receive
    case send
    case swap
    case cashOut
 
    var title: String {
        switch self {
        case .buy:
            return L10n.buy
        case .receive:
            return L10n.receive
        case .send:
            return L10n.send
        case .swap:
            return L10n.swap
        case .cashOut:
            return L10n.cashOut
        }
    }
    
    var icon: UIImage {
        switch self {
        case .receive:
            return .homeReceive
        case .buy:
            return .homeBuy
        case .send:
            return .homeSend
        case .swap:
            return .homeSwap
        case .cashOut:
            return .cashOut
        }
    }
}
