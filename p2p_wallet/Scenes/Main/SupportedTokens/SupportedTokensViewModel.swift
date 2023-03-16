//
//  SupportedTokensViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Combine
import Foundation
import KeyAppBusiness
import Resolver
import SolanaSwift
import Wormhole

enum SupportedTokensAction {
    case receive(SupportedTokenItem)
}

class SupportedTokensViewModel: BaseViewModel, ObservableObject {
    let actionSubject: PassthroughSubject<SupportedTokensAction, Never> = .init()

    /// Solana tokens
    @Published private var solana: Set<SupportedTokenItem> = []

    /// Ethereum tokens
    @Published private var ethereum: Set<SupportedTokenItem> = []

    /// Renderable final token list
    @Published var tokens: [SupportedTokenItem] = []

    /// Filter keyword
    @Published var filter: String = ""

    init(mock: [SupportedTokenItem]) {
        tokens = mock
    }

    init(
        solanaTokenRepository: SolanaTokensRepository = Resolver.resolve(),
        ethereumTokenRepository: EthereumTokensRepository = Resolver.resolve()
    ) {
        super.init()

        // Get solana token list
        Task {
            // List all tokens
            let tokens = try await solanaTokenRepository.getTokensList()

            // Filter tokens
            let filteredToken = tokens
                .filter { token in
                    // Filter tokens by tags
                    !token.tags.contains(where: { $0.name == "nft" }) &&
                        !token.tags.contains(where: { $0.name == "leveraged" }) &&
                        !token.tags.contains(where: { $0.name == "bull" }) &&
                        !token.tags.contains(where: { $0.name == "lp-token" })
                }
                .filter { token in
                    // Ignore stable coin by symbol, because there are many of them.
                    !SupportedTokensBusinnes.wellKnownTokens.map(\.symbol).contains(token.symbol.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                .map { SupportedTokenItem(solana: $0) }

            solana = Set(SupportedTokensBusinnes.wellKnownTokens + filteredToken)
        }

        // Build final tokens list.
        $solana
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { Array($0) }
            .combineLatest($filter)
            .map(SupportedTokensBusinnes.filterByKeyword)
            .map { [weak self] in $0.sorted { SupportedTokensBusinnes.sortToken(lhs: $0, rhs: $1, filter: self?.filter ?? "") } }
            .receive(on: RunLoop.main)
            .weakAssign(to: \.tokens, on: self)
            .store(in: &subscriptions)
    }

    func onTap(_ item: SupportedTokenItem) {
        actionSubject.send(.receive(item))
    }
}

enum SupportedTokensBusinnes {
    /// Filter by symbol or name.
    static func filterByKeyword(tokens: [SupportedTokenItem], filter: String) -> [SupportedTokenItem] {
        if filter.isEmpty {
            return tokens
        } else {
            let lowercasedFilter = filter.lowercased()
            return tokens
                .filter {
                    // Filter by title (token name) and subtitle (token symbol
                    $0.symbol.lowercased().contains(lowercasedFilter)
                        || $0.name.lowercased().contains(lowercasedFilter)
                }
        }
    }

    /// Sort tokens by priority and name.
    static func sortToken(lhs: SupportedTokenItem, rhs: SupportedTokenItem, filter: String) -> Bool {
        let lhsIndex = Self.symbolPriority(lhs.symbol)
        let rhsIndex = Self.symbolPriority(rhs.symbol)

        // Sort by index.

        if filter.isEmpty || lhs.symbol != filter || rhs.symbol != filter {
            if lhsIndex != rhsIndex {
                return lhsIndex < rhsIndex
            } else {
                // Sort by symbol.
                return lhs.symbol < rhs.symbol
            }
        } else {
            return lhs.symbol == filter
        }
    }

    /// Get symbol priority. Case sensitive.
    static func symbolPriority(_ symbol: String) -> Int {
        let priority: [String] = [
            "USDC",
            "USDT",
            "ETH",
            "SOL",
            "AVAX",
            "BNB",
            "WBNB",
            "MATIC",
            "CRV"
        ]

        return priority.firstIndex { i in i == symbol } ?? priority.count
    }

    static var knownSynonymTokens: [String: String] {
        // key - solana symbol, value - eth symbol
        [
            "BNB": "WBNB",
            "AVAX": "WAVAX"
        ]
    }

    static var wellKnownTokens: [SupportedTokenItem] {
        [
            SupportedTokenItem(
                icon: .url(URL(string: "https://assets.coingecko.com/coins/images/4128/large/solana.png?1640133422")!),
                name: "Solana", symbol: "SOL", availableNetwork: [.ethereum, .solana]
            ),
            SupportedTokenItem(
                icon: .url(URL(string: "https://assets.coingecko.com/coins/images/279/large/ethereum.png?1595348880")!),
                name: "Ethereum", symbol: "ETH", availableNetwork: [.ethereum, .solana]
            ),
            SupportedTokenItem(
                icon: .url(URL(string: "https://assets.coingecko.com/coins/images/6319/large/USD_Coin_icon.png?1547042389")!),
                name: "USDC", symbol: "USDC", availableNetwork: [.ethereum, .solana]
            ),
            SupportedTokenItem(
                icon: .url(URL(string: "https://assets.coingecko.com/coins/images/325/large/Tether.png?1668148663")!),
                name: "USDT", symbol: "USDT", availableNetwork: [.ethereum, .solana]
            ),
            SupportedTokenItem(
                icon: .url(URL(string: "https://assets.coingecko.com/coins/images/12559/large/Avalanche_Circle_RedWhite_Trans.png?1670992574")!),
                name: "Avalanche", symbol: "AVAX", availableNetwork: [.ethereum, .solana]
            ),
            SupportedTokenItem(
                icon: .url(URL(string: "https://assets.coingecko.com/coins/images/825/large/bnb-icon2_2x.png?1644979850")!),
                name: "Binance Coin", symbol: "BNB", availableNetwork: [.ethereum, .solana]
            ),
            SupportedTokenItem(
                icon: .url(URL(string: "https://assets.coingecko.com/coins/images/4713/large/matic-token-icon.png?1624446912")!),
                name: "Polygon", symbol: "MATIC", availableNetwork: [.ethereum, .solana]
            ),
            SupportedTokenItem(
                icon: .url(URL(string: "https://assets.coingecko.com/coins/images/12124/large/Curve.png?1597369484")!),
                name: "Curve DAO Token", symbol: "CRV", availableNetwork: [.ethereum, .solana]
            )
        ]
    }
}
