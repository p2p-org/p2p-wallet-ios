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
    
    static let items: [MockedRendableDetailTransaction] = [
        .send(),
        .sending(),
        .failedSend(),
        .receive(),
        .swap1(),
        .mint(),
        .burn(),
        .stake(),
        .unstake(),
        .createAccount(),
        .closeAccount(),
        .unknown()
    ]
    
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
    
    static func sending() -> Self {
        .init(
            status: .loading(message: L10n.theTransactionWillBeCompletedInAFewSeconds),
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
    
    static func failedSend() -> Self {
        .init(
            status: .error(message: NSAttributedString(string: L10n.theTransactionWasRejectedByTheSolanaBlockchain), error: nil),
            title: "Transaction failed",
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
    
    static func receive() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            amountInFiat: .positive("$5 268.65"),
            amountInToken: "0.3271523 renBTC",
            extra: [
                .init(title: L10n.receivedFrom, value: "@kirill.key", copyableValue: "@kirill.key")
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func swap1() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .double(URL(string: Token.nativeSolana.logoURI!)!, URL(string: Token.eth.logoURI!)!),
            amountInFiat: .unchanged("$571.95"),
            amountInToken: "120 SOL → 3.5 ETH",
            extra: [
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func swap2() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .icon(.buttonSwap),
            amountInFiat: .unchanged("$571.95"),
            amountInToken: "35.7766264 SOL → 12 USDC",
            extra: [
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func swap3() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .icon(.buttonSwap),
            amountInFiat: .negative("$571.95"),
            amountInToken: "35.7766264 SOL → 12 USDC",
            extra: [
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func burn() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            amountInFiat: .negative("-$5 268.65"),
            amountInToken: "0.3271523 renBTC",
            extra: [
                .init(title: L10n.signature("Burn"), value: "FfRB...BeJEr"),
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func mint() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            amountInFiat: .positive("+$5 268.65"),
            amountInToken: "0.3271523 renBTC",
            extra: [
                .init(title: L10n.signature("Mint"), value: "FfRB...BeJEr"),
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func unstake() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            amountInFiat: .positive("+$122.12"),
            amountInToken: "5.21 SOL",
            extra: [
                .init(title: L10n.signature("Unstake"), value: "FfRB...BeJEr"),
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func stake() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            amountInFiat: .negative("-$122.12"),
            amountInToken: "5.21 SOL",
            extra: [
                .init(title: L10n.signature("Stake"), value: "FfRB...BeJEr"),
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func closeAccount() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .icon(.closeToken),
            amountInFiat: .unchanged(""),
            amountInToken: "No balance change",
            extra: [
                .init(title: "Account closed", value: "FfRB...BeJEr"),
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func createAccount() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .icon(.transactionCreateAccount),
            amountInFiat: .positive("+$1"),
            amountInToken: "1 USDC",
            extra: [
                .init(title: "Account created", value: "FfRB...BeJEr"),
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func unknown() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .icon(.planet),
            amountInFiat: .positive("-$122.12"),
            amountInToken: "5.21 SOL",
            extra: [
                .init(title: "Signature", value: "FfRB...BeJEr"),
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
}
