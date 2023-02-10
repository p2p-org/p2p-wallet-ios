//
//  NewHistoryViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 01.02.2023.
//

import Combine
import Foundation
import History
import Resolver
import RxSwift
import SolanaSwift
import TransactionParser

enum NewHistoryAction {
    case openDetailByParsedTransaction(ParsedTransaction)
}

class NewHistoryViewModel: BaseViewModel, ObservableObject {
    typealias HistoryItem = NewHistoryRendableItem

    var disposeBag = DisposeBag()

    @Published var items: [NewHistoryItem] = []

    var sections: [NewHistorySection] {
        let dictionary = Dictionary(grouping: items) { item -> Date in
            if case let .rendable(rendableItem) = item {
                return Calendar.current.startOfDay(for: rendableItem.date)
            }
            return Calendar.current.startOfDay(for: Date())
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.shared

        let result = dictionary.keys.sorted().reversed()
            .map { key in
                NewHistorySection(title: dateFormatter.string(from: key), items: dictionary[key] ?? [])
            }

        for section in result {
            print(section.id)
            for item in section.items {
                print(item.id)
            }
        }

        return result
    }

    let actionSubject = PassthroughSubject<NewHistoryAction, Never>()

    private var repository: NewHistoryRepository

    @Injected var walletRepository: WalletsRepository

    init(initialSections: [NewHistorySection]) {
        repository = EmptyNewHistoryRepository()
    }

    override init() {
        repository = EmptyNewHistoryRepository()

        super.init()

        let transactionRepositopy = SolanaTransactionRepository(solanaAPIClient: Resolver.resolve())
        walletRepository.dataObservable
            .subscribe(onNext: { [weak self] wallets in
                guard let wallets = wallets else { return }
                let accountStreamSources = wallets
                    .reversed()
                    .map { wallet in
                        AccountStreamSource(
                            account: wallet.pubkey ?? "",
                            symbol: wallet.token.symbol,
                            transactionRepository: transactionRepositopy
                        )
                    }

                let source = MultipleStreamSource(sources: accountStreamSources)

                self?.repository = NewHistoryRepositoryWithOldProvider(source: source)
                Task {
                    self?.items = []
                    await self?.fetchMore()
                }
            })
            .disposed(by: disposeBag)
    }

    func fetchMore() async {
        do {
            let result = try await repository.fetch(20)
                .filter { item in !self.items.contains(where: { $0.id == item.id }) }

            items.append(contentsOf: result.map { .rendable($0) })
        } catch {
            print(error)
        }
    }

    func onTap(item: any NewHistoryRendableItem) {
        if let item = item as? RendableParsedTransaction {
            actionSubject.send(.openDetailByParsedTransaction(item.trx))
        }
    }
}
