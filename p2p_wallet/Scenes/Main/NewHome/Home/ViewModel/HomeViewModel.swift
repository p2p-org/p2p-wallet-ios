//
//  HomeViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import Combine
import Foundation
import Resolver
import RxCombine
import RxSwift

class HomeViewModel: ObservableObject {
    @Published var state = State.pending

    private var cancellables = Set<AnyCancellable>()

    private var initStateFinished = false

    init() {
        let walletsRepository = Resolver.resolve(WalletsRepository.self)

        Observable.combineLatest(
            walletsRepository.stateObservable,
            walletsRepository.dataObservable.filter { $0 != nil }
        ).map { state, data -> State in
            switch state {
            case .initializing, .loading:
                return State.pending
            case .loaded, .error:
                let amount = data?.reduce(0) { partialResult, wallet in partialResult + wallet.amount } ?? 0
                return amount > 0 ? State.withTokens : State.empty
            }
        }
        .asPublisher()
        .assertNoFailure()
        .sink(receiveValue: { [weak self] in
            guard let self = self else { return }
            if self.initStateFinished, $0 == .pending { return }

            self.state = $0
            if $0 != .pending {
                self.initStateFinished = true
            }
        })
        .store(in: &cancellables)

        walletsRepository.reload()
    }
}

extension HomeViewModel {
    enum State {
        case pending
        case withTokens
        case empty
    }
}
