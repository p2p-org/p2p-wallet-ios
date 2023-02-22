//
//  RendableDetailTransaction+Mock.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Combine
import Foundation
import SolanaSwift

struct MockedRendableDetailTransaction: RendableDetailTransaction {
    var status: DetailTransactionStatus
    var title: String
    var subtitle: String
    var signature: String?
    var icon: DetailTransactionIcon
    var amountInFiat: DetailTransactionChange
    var amountInToken: String
    var extra: [DetailTransactionExtraInfo]
    var actions: [DetailTransactionAction]
    
    static func send() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            signature: "2PmjWNqQUd9AedT1nnFBdhRdw5JXkNTajBFZ6RmfpPorTMKcxBXkAPER2RmMLnuSS9RKsA1kynhCc8d6LjFQamLs",
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            amountInFiat: .negative("-$122.12"),
            amountInToken: "5.21 SOL",
            extra: [
                .init(title: L10n.sendTo, value: "@kirill.key", copyableValue: "@kirill.key"),
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
}
