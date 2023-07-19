import Foundation
import KeyAppKitCore
import SolanaSwift
import UIKit

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
            icon = .url(url)
        } else {
            icon = .placeholder
        }

        name = token.name.trimmingCharacters(in: .whitespacesAndNewlines)
        symbol = token.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        availableNetwork = [.solana]
    }

    func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
        symbol.hash(into: &hasher)
    }

    static func == (lhs: SupportedTokenItem, rhs: SupportedTokenItem) -> Bool {
        lhs.name == rhs.name && lhs.symbol == rhs.symbol && lhs.availableNetwork == rhs.availableNetwork
    }
}
