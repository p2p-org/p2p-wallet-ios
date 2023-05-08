//
//  File.swift
//
//
//  Created by Giang Long Tran on 14.04.2023.
//

import Foundation
import SolanaSwift
import KeyAppKitCore

public struct RecipientSearchConfig {
    public var wallets: [SolanaAccount]
    public var ethereumAccount: String?
    public var tokens: [String: Token]

    public var ethereumSearch: Bool

    public init(wallets: [SolanaAccount], ethereumAccount: String?, tokens: [String: Token], ethereumSearch: Bool) {
        self.wallets = wallets
        self.ethereumAccount = ethereumAccount
        self.tokens = tokens
        self.ethereumSearch = ethereumSearch
    }

    public init() {
        wallets = []
        ethereumAccount = nil
        tokens = [:]
        ethereumSearch = false
    }
}
