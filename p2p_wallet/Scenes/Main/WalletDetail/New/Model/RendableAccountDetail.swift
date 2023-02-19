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
}
