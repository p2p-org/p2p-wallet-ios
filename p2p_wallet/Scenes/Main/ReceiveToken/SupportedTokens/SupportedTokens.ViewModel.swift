//
//  SupportedTokens.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.01.2022.
//

import Foundation
import RxSwift
import RxCocoa
import SolanaSwift
import BECollectionView

protocol SupportedTokensViewModelType: BEListViewModelType {
    var navigationDriver: Driver<SupportedTokens.NavigatableScene?> { get }

    func search(keyword: String)
}

extension SupportedTokens {
    final class ViewModel: BEListViewModel<SolanaSDK.Token> {
        // MARK: - Dependencies
        @Injected private var tokensRepository: TokensRepository

        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private var keyword: String?

        override func createRequest() -> Single<[SolanaSDK.Token]> {
            return tokensRepository.getTokensList()
                .map { $0.excludingSpecialTokens() }
        }

        override func map(newData: [SolanaSDK.Token]) -> [SolanaSDK.Token] {
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
            if let keyword = keyword {
                data = data.filter { $0.hasKeyword(keyword) }
            }
            return data
        }

        private func getTokenPriority(_ token: SolanaSDK.Token) -> Int {
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
    var navigationDriver: Driver<SupportedTokens.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    // MARK: - Actions
    func search(keyword: String) {
        guard self.keyword != keyword else { return }
        self.keyword = keyword
        reload()
    }
}

private extension SolanaSDK.Token {
    func hasKeyword(_ keyword: String) -> Bool {
        symbol.lowercased().contains(keyword.lowercased())
            || name.lowercased().contains(keyword.lowercased())
    }
}
