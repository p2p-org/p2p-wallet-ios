//
//  StandaloneRendableAccountDetails.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Foundation

struct MockRendableAccountDetails: RendableAccountDetails {
    var title: String
    var amountInToken: String
    var amountInFiat: String
    var actions: [RendableAccountDetailsAction]
    var onAction: (RendableAccountDetailsAction) -> Void
}
