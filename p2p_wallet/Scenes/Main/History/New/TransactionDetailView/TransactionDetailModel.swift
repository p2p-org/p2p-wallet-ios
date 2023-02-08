//
//  DetailTransactionModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

import Combine
import Foundation
import SolanaSwift

struct DetailTransactionExtraInfo {
    let title: String
    let value: String
    
    let copyable: Bool
    
    init(title: String, value: String, copyable: Bool = true) {
        self.title = title
        self.value = value
        self.copyable = copyable
    }
}

enum DetailTransactionAction {
    case share
    case explorer
}

enum DetailTransactionIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}

enum DetailTransactionChange {
    case positive(String)
    case negative(String)
    case unchanged(String)
    
    var value: String {
        switch self {
        case let .positive(value): return value
        case let .negative(value): return value
        case let .unchanged(value): return value
        }
    }
}

enum DetailTransactionStatus: Equatable {
    case loading(message: String)
    case succeed(message: String)
    case error(message: NSAttributedString)
}

protocol RendableDetailTransaction {
    var status: CurrentValueSubject<DetailTransactionStatus, Never> { get }
    
    var title: String { get }
    
    var subtitle: String { get }
    
    var signature: String? { get }
    
    var icon: DetailTransactionIcon { get }
    
    var amountInFiat: DetailTransactionChange { get }
    
    var amountInToken: String { get }
    
    var extra: [DetailTransactionExtraInfo] { get }
    
    var actions: [DetailTransactionAction] { get }
}

struct MockedRendableDetailTransaction: RendableDetailTransaction {
    var status: CurrentValueSubject<DetailTransactionStatus, Never>
    var title: String
    var subtitle: String
    var signature: String?
    var icon: DetailTransactionIcon
    var amountInFiat: DetailTransactionChange
    var amountInToken: String
    var extra: [DetailTransactionExtraInfo]
    var actions: [DetailTransactionAction]
    
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            signature: "2PmjWNqQUd9AedT1nnFBdhRdw5JXkNTajBFZ6RmfpPorTMKcxBXkAPER2RmMLnuSS9RKsA1kynhCc8d6LjFQamLs",
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            amountInFiat: .negative("-$122.12"),
            amountInToken: "5.21 SOL",
            extra: [
                .init(title: L10n.sendTo, value: "@kirill.key", copyable: true),
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
            status: .init(
                .loading(message: L10n.itUsuallyTakes520SecondsForATransactionToComplete)
            ),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            signature: "2PmjWNqQUd9AedT1nnFBdhRdw5JXkNTajBFZ6RmfpPorTMKcxBXkAPER2RmMLnuSS9RKsA1kynhCc8d6LjFQamLs",
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            amountInFiat: .negative("-$122.12"),
            amountInToken: "5.21 SOL",
            extra: [
                .init(title: L10n.sendTo, value: "@kirill.key", copyable: true),
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
            status: .init(
                .error(message: NSAttributedString(string: L10n.theTransactionWasRejectedByTheSolanaBlockchain))
            ),
            title: "Transaction failed",
            subtitle: "August 22, 2022 @ 08:08",
            signature: "2PmjWNqQUd9AedT1nnFBdhRdw5JXkNTajBFZ6RmfpPorTMKcxBXkAPER2RmMLnuSS9RKsA1kynhCc8d6LjFQamLs",
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            amountInFiat: .negative("-$122.12"),
            amountInToken: "5.21 SOL",
            extra: [
                .init(title: L10n.sendTo, value: "@kirill.key", copyable: true),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            icon: .single(URL(string: Token.renBTC.logoURI!)!),
            amountInFiat: .positive("$5 268.65"),
            amountInToken: "0.3271523 renBTC",
            extra: [
                .init(title: L10n.receivedFrom, value: "@kirill.key", copyable: true)
            ],
            actions: [
                .share,
                .explorer
            ]
        )
    }
    
    static func swap1() -> Self {
        .init(
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
            status: .init(
                .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟)
            ),
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
