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

            // List stable coins
            let stableCoints: [SolanaSwift.Token] = [
                .usdt,
                .usdc,
                .eth,
                .nativeSolana
            ]

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
                    !stableCoints.map(\.symbol).contains(token.symbol.trimmingCharacters(in: .whitespacesAndNewlines))
                }

            solana = Set(
                (stableCoints + filteredToken).map { SupportedTokenItem(solana: $0) }
            )
        }

        // Get ethereum list
        Task {
            let tokens = try await WormholeService.supportedTokens(tokenService: ethereumTokenRepository)
            ethereum = Set(tokens.map { token in SupportedTokenItem(ethereum: token) })
        }

        // Build final tokens list.
        Publishers.Zip($solana, $ethereum)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map(SupportedTokensBusinnes.combineSolanaWithEthereum)
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

private enum SupportedTokensBusinnes {
    /// Combine solana and ethereum tokens.
    static func combineSolanaWithEthereum(solana: Set<SupportedTokenItem>, ethereum: Set<SupportedTokenItem>) -> [SupportedTokenItem] {
        var result: [SupportedTokenItem] = Array(solana)

        // Merge by symbol. Is it a good way?
        for ethereumToken in ethereum {
            let index = result.firstIndex { solanaToken in solanaToken.symbol == ethereumToken.symbol }
            if let index {
                // Merge with solana.

                result[index].availableNetwork += [.ethereum]

                // result[index] = ethereumToken
                // result[index].availableNetwork = [.solana, .ethereum]
            } else {
                // Insert as ethereum only token.
                result += [ethereumToken]
            }
        }

        return result
    }

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
            "SOL"
        ]

        return priority.firstIndex { i in i == symbol } ?? priority.count
    }
}
