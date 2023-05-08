import Resolver
import Combine
import KeyAppKitCore
import KeyAppBusiness

final class ChooseSwapTokenService: ChooseItemService {

    let otherTokensTitle = L10n.allTokens
    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> {
        statePublisher.eraseToAnyPublisher()
    }

    private let statePublisher: CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>
    private let swapTokens: CurrentValueSubject<[SwapToken], Never>
    private let fromToken: Bool
    private let preferTokens: [String]

    @Injected private var accountsService: SolanaAccountsService
    private var subscriptions = [AnyCancellable]()

    init(swapTokens: [SwapToken], fromToken: Bool) {
        self.swapTokens = CurrentValueSubject(swapTokens)
        self.fromToken = fromToken

        if fromToken {
            preferTokens = ["USDC", "USDT"]
        } else {
            preferTokens = SwapToken.preferTokens
        }

        statePublisher = CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>(AsyncValueState(status: .ready, value: []))

        bind()
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let sections = items.map { section in
            guard let tokens = section.items as? [SwapToken] else { return section }
            return ChooseItemListSection(items: tokens.sorted(
                preferTokens: preferTokens,
                sortByName: !fromToken
            ))
        }
        return validateEmpty(sections: sections)
    }

    func sortFiltered(by keyword: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let sections = items.map { section in
            guard var tokens = section.items as? [SwapToken] else { return section }
            tokens = tokens.sorted(by: { lhs, rhs in
                // Put 'start' matches in the beginning of array, 'contains' after
                lhs.token.name.lowercased().starts(with: keyword) || lhs.token.symbol.lowercased().starts(with: keyword)
            })
            if let index = tokens.firstIndex(where: {
                $0.token.name.lowercased().elementsEqual(keyword) || $0.token.symbol.lowercased().elementsEqual(keyword)
            }) {
                // Put exact match in the first place
                let exactKeywordToken = tokens.remove(at: index)
                tokens.insert(exactKeywordToken, at: .zero)
            }
            return ChooseItemListSection(items: tokens)
        }
        return validateEmpty(sections: sections)
    }
}

private extension ChooseSwapTokenService {
    func bind() {
        swapTokens
            .sink { [weak self] tokens in
                guard let self else { return }
                var firstSection = [SwapToken]()
                var secondSection = [SwapToken]()
                if self.fromToken {
                    firstSection = tokens.filter { $0.userWallet != nil }
                    secondSection = tokens.filter { $0.userWallet == nil }
                } else {
                    let preferTokens = Set(self.preferTokens)
                    tokens.forEach {
                        if preferTokens.contains($0.token.symbol) {
                            firstSection.append($0)
                        } else {
                            secondSection.append($0)
                        }
                    }
                }

                self.statePublisher.send(
                    AsyncValueState(status: .ready, value: [
                        ChooseItemListSection(items: firstSection),
                        ChooseItemListSection(items: secondSection)
                    ])
                )
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest(accountsService.statePublisher, swapTokens.eraseToAnyPublisher())
            .map({ ($0.0.value, $0.1) })
            .sink { [weak self] accounts, swapTokens in
                guard let self else { return }
                let newSwapTokens = swapTokens.map { swapToken in
                    if let account = accounts.first(where: { $0.mintAddress == swapToken.address }) {
                        return SwapToken(token: swapToken.token, userWallet: account)
                    }
                    return SwapToken(token: swapToken.token, userWallet: nil)
                }
                self.swapTokens.send(newSwapTokens)
            }
            .store(in: &subscriptions)
    }

    func validateEmpty(sections: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let isEmpty = sections.flatMap { $0.items }.isEmpty
        return isEmpty ? [] : sections
    }
}

// MARK: - Sort Rules

private extension Array where Element == SwapToken {
    func sorted(preferTokens: [String], sortByName: Bool) -> Self {
        var preferOrder = [String: Int]()
        preferTokens.enumerated().forEach {
            preferOrder[$0.1] = $0.0 + 1
        }
        return sorted { (lhs: SwapToken, rhs: SwapToken) -> Bool in
            if preferOrder[lhs.token.symbol] != nil || preferOrder[rhs.token.symbol] != nil {
                return (preferOrder[lhs.token.symbol] ?? 3) < (preferOrder[rhs.token.symbol] ?? 3)
            } else if sortByName {
                return lhs.token.name < rhs.token.name
            } else if let lhsWallet = lhs.userWallet, let rhsWallet = rhs.userWallet {
                return lhsWallet._amountInCurrentFiat > rhsWallet._amountInCurrentFiat
            } else if lhs.userWallet != nil || rhs.userWallet != nil {
                return false
            } else {
                return lhs.token.name < rhs.token.name
            }
        }
    }
}
