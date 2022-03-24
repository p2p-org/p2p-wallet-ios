//
//  SupportedTokens.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 30.01.2022.
//

import BECollectionView
import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

protocol SupportedTokensViewModelType: BEListViewModelType {
    func search(keyword: String)
}

extension SupportedTokens {
    final class ViewModel: BEListViewModel<SolanaSDK.Token> {
        // MARK: - Dependencies

        private let tokensRepository: TokensRepository

        // MARK: - Properties

        private let disposeBag = DisposeBag()

        // MARK: - Subject

        private var keywordSubject = BehaviorRelay<String?>(value: nil)

        init(tokensRepository: TokensRepository) {
            self.tokensRepository = tokensRepository

            super.init()

            keywordSubject
                .distinctUntilChanged()
                .throttle(.milliseconds(400), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.reload()
                })
                .disposed(by: disposeBag)
        }

        override func createRequest() -> Single<[SolanaSDK.Token]> {
            var existingSymbols: Set<String> = []

            return tokensRepository.getTokensList()
                .map { tokens -> [SolanaSDK.Token] in
                    tokens
                        .excludingSpecialTokens()
                        .filter { existingSymbols.insert($0.symbol).inserted }
                }
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
            if let keyword = keywordSubject.value, !keyword.isEmpty {
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
    // MARK: - Actions

    func search(keyword: String) {
        keywordSubject.accept(keyword)
    }
}

private extension SolanaSDK.Token {
    func hasKeyword(_ keyword: String) -> Bool {
        symbol.lowercased().contains(keyword.lowercased())
            || name.lowercased().contains(keyword.lowercased())
    }
}
