//
//  RendableDetailTransaction+Mock.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Combine
import Foundation
import SolanaSwift

struct MockedRendableDetailTransaction: RendableTransactionDetail {
    var status: TransactionDetailStatus
    var title: String
    var subtitle: String
    var signature: String?
    var icon: TransactionDetailIcon
    var amountInFiat: TransactionDetailChange
    var amountInToken: String
    var extra: [TransactionDetailExtraInfo]
    var actions: [TransactionDetailAction]
    var buttonTitle: String

    init(
        status: TransactionDetailStatus,
        title: String,
        subtitle: String,
        signature: String? = nil,
        icon: TransactionDetailIcon,
        amountInFiat: TransactionDetailChange,
        amountInToken: String,
        extra: [TransactionDetailExtraInfo],
        actions: [TransactionDetailAction],
        buttonTitle: String = L10n.done
    ) {
        self.status = status
        self.title = title
        self.subtitle = subtitle
        self.signature = signature
        self.icon = icon
        self.amountInFiat = amountInFiat
        self.amountInToken = amountInToken
        self.extra = extra
        self.actions = actions
        self.buttonTitle = buttonTitle
    }

    static let items: [MockedRendableDetailTransaction] = [.send()]

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
                .init(title: L10n.sendTo, values: [.init(text: "@kirill.key")], copyableValue: "@kirill.key"),
                .init(title: L10n.transactionFee, values: [.init(text: L10n.freePaidByKeyApp)]),
            ],
            actions: [
                .share,
                .explorer,
            ]
        )
    }
}
