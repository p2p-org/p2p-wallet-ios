//
//  SupportedTokenItem.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import KeyAppKitCore
import SolanaSwift

enum SupportedTokenItemIcon {
    case url(URL)
    case image(UIImage)
    case placeholder
}

enum SupportedTokenItemNetwork: Int, Identifiable, Comparable {
    var id: Int { rawValue }

    case solana
    case ethereum

    static func < (lhs: SupportedTokenItemNetwork, rhs: SupportedTokenItemNetwork) -> Bool {
        lhs.id < rhs.id
    }
}

struct SupportedTokenItem: Identifiable, Hashable {
    var id: String { name + symbol }

    let icon: SupportedTokenItemIcon

    let name: String

    let symbol: String

    var availableNetwork: [SupportedTokenItemNetwork]

    init(icon: SupportedTokenItemIcon, name: String, symbol: String, availableNetwork: Set<SupportedTokenItemNetwork>) {
        self.icon = icon
        self.name = name
        self.symbol = symbol
        self.availableNetwork = [SupportedTokenItemNetwork](availableNetwork)
            .sorted()
    }

    init(solana token: SolanaToken) {
        if
            let uri = token.logoURI,
            let url = URL(string: uri)
        {
            self.icon = .url(url)
        } else {
            self.icon = .placeholder
        }

        self.name = token.name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.symbol = token.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        self.availableNetwork = [.solana]
    }

    init(ethereum token: EthereumToken) {
        if let url = token.logo {
            self.icon = .url(url)
        } else {
            self.icon = .placeholder
        }

        self.name = token.name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.symbol = token.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        self.availableNetwork = [.ethereum]
    }

    func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
        symbol.hash(into: &hasher)
    }

    static func == (lhs: SupportedTokenItem, rhs: SupportedTokenItem) -> Bool {
        lhs.name == rhs.name && lhs.symbol == rhs.symbol && lhs.availableNetwork == rhs.availableNetwork
    }
}
