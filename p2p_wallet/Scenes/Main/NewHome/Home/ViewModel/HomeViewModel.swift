//
//  HomeViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import RxCombine
import RxSwift
import SolanaSwift

class HomeViewModel: ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationService
    @Injected private var accountStorage: AccountStorageType
    private let walletsRepository: WalletsRepository

    @Published var state = State.pending
    @Published var address = ""

    private var cancellables = Set<AnyCancellable>()

    private let error = PassthroughSubject<Bool, Never>()
    var errorShow: AnyPublisher<Bool, Never> { error.eraseToAnyPublisher() }

    private var initStateFinished = false

    init() {
        let walletsRepository = Resolver.resolve(WalletsRepository.self)
        self.walletsRepository = walletsRepository
        address = accountStorage.account?.publicKey.base58EncodedString.shortAddress ?? ""

        Observable.combineLatest(
            walletsRepository.stateObservable,
            walletsRepository.dataObservable.filter { $0 != nil }
        ).map { state, data -> (State, Double?) in
            switch state {
            case .initializing, .loading:
                return (State.pending, nil)
            case .loaded, .error:
                let fiatAmount = data?.reduce(0) { $0 + $1.amountInCurrentFiat } ?? 0
                return (fiatAmount > 0 ? State.withTokens : State.empty, fiatAmount)
            }
        }
        .asPublisher()
        .assertNoFailure()
        .sink(receiveValue: { [weak self] state, amount in
            guard let self = self else { return }
            if self.initStateFinished, state == .pending { return }

            if let address = self.accountStorage.account?.publicKey.base58EncodedString.shortAddress {
                self.address = address
            }
            self.state = state
            if state != .pending {
                self.initStateFinished = true
                self.analyticsManager.setIdentifier(AmplitudeIdentifier.userHasPositiveBalance(positive: amount > 0))
                if let amount = amount {
                    let formatted = round(amount * 100) / 100.0
                    self.analyticsManager.setIdentifier(AmplitudeIdentifier.userAggregateBalance(balance: formatted))
                }
            }
        })
        .store(in: &cancellables)
        walletsRepository.stateObservable
            .asPublisher()
            .assertNoFailure()
            .map { $0 == .error }
            .sink(receiveValue: { [weak self] hasError in
                if hasError, self?.walletsRepository.getError() != nil {
                    self?.error.send(true)
                } else {
                    self?.error.send(false)
                }
            })
            .store(in: &cancellables)

        walletsRepository.reload()
    }

    func copyToClipboard() {
        clipboardManager.copyToClipboard(walletsRepository.nativeWallet?.pubkey ?? "")
        notificationsService.showInAppNotification(.done(L10n.addressCopiedToClipboard))
        analyticsManager.log(event: AmplitudeEvent.mainCopyAddress)
    }
}

extension HomeViewModel {
    enum State {
        case pending
        case withTokens
        case empty
    }
}

private extension String {
    var shortAddress: String {
        "\(prefix(4))...\(suffix(4))"
    }
}
