//
//  SupportedTokens.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.01.2022.
//

import BECollectionView_Combine
import Combine
import Foundation
import Resolver
import SolanaSwift

protocol SupportedTokensViewModelType: BECollectionViewModelType {
    func search(keyword: String)

    var keyword: String? { get }
}

extension SupportedTokens {
    final class ViewModel: BECollectionViewModel<Token> {
        // MARK: - Dependencies

        @Injected private var tokensRepository: SolanaTokensRepository

        // MARK: - Properties

        private var subscriptions = [AnyCancellable]()

        @Published var keyword: String?

        init() {
            super.init()

            $keyword
                .removeDuplicates()
                .throttle(for: .milliseconds(400), scheduler: RunLoop.main, latest: true)
                .sink { [weak self] _ in
                    self?.reload()
                }
                .store(in: &subscriptions)
        }

        override func createRequest() async throws -> [Token] {
            var existingSymbols: Set<String> = []
            return Array(try await tokensRepository.getTokensList())
                .excludingSpecialTokens()
                .filter { existingSymbols.insert($0.symbol).inserted }
        }

        override func map(newData: [Token]) -> [Token] {
            var data = super.map(newData: newData)
                .sorted { firstToken, secondToken in
                    let firstTokenPriority = getTokenPriority(firstToken)
                    let secondTokenPriority = getTokenPriority(secondToken)

                    if firstTokenPriority == secondTokenPriority {
                        return firstToken.name < secondToken.name
                    } else {
                        return firstTokenPriority > secondTokenPriority
                    }
                }
            if let keyword = keyword, !keyword.isEmpty {
                data = data.filter { $0.hasKeyword(keyword) }
            }
            return data
        }

        private func getTokenPriority(_ token: Token) -> Int {
            switch token.symbol {
            case "SOL":
                return .max
            case "USDC":
                return Int.max - 1
            case "BTC":
                return Int.max - 2
            case "USDT":
                return Int.max - 3
            case "ETH":
                return Int.max - 4
            default:
                return 0
            }
        }
    }
}

extension SupportedTokens.ViewModel: SupportedTokensViewModelType {
    // MARK: - Actions

    func search(keyword: String) { self.keyword = keyword }
}

private extension Token {
    func hasKeyword(_ keyword: String) -> Bool {
        symbol.lowercased().contains(keyword.lowercased())
            || name.lowercased().contains(keyword.lowercased())
    }
}
