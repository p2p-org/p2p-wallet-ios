//
//  StandaloneRendableAccountDetail.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Foundation

struct MockRendableAccountDetail: RendableAccountDetail {
    var title: String
    var amountInToken: String
    var amountInFiat: String
    var actions: [RendableAccountDetailAction]
    var onAction: (RendableAccountDetailAction) -> Void
}
