//
//  DetailTransactionModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

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

enum DetailTransactionIcon {
    case icon(UIImage)
    case single(URL)
    case double(URL, URL)
}

enum DetailTransactionStatus {
    case loading(message: String)
    case succeed(message: String)
    case error(message: NSAttributedString)
}

protocol RendableDetailTransaction {
    var status: DetailTransactionStatus { get }
    
    var title: String { get }
    
    var subtitle: String { get }
    
    var signature: String? { get }
    
    var icon: DetailTransactionIcon { get }
    
    var amountInFiat: String { get }
    
    var amountInToken: String { get }
    
    var extra: [DetailTransactionExtraInfo] { get }
}

struct MockedRendableDetailTransaction: RendableDetailTransaction {
    var status: DetailTransactionStatus
    var title: String
    var subtitle: String
    var signature: String?
    var icon: DetailTransactionIcon
    var amountInFiat: String
    var amountInToken: String
    var extra: [DetailTransactionExtraInfo]
    
    static func send() -> Self {
        .init(
            status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted🤟),
            title: "Transaction submitted",
            subtitle: "August 22, 2022 @ 08:08",
            signature: "2PmjWNqQUd9AedT1nnFBdhRdw5JXkNTajBFZ6RmfpPorTMKcxBXkAPER2RmMLnuSS9RKsA1kynhCc8d6LjFQamLs",
            icon: .single(URL(string: Token.nativeSolana.logoURI!)!),
            amountInFiat: "-$10",
            amountInToken: "0.622181417 SOL",
            extra: [
                .init(title: L10n.sendTo, value: "@kirill.key", copyable: true),
                .init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp)
            ]
        )
    }
}
