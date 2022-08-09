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
    private let walletsRepository = Resolver.resolve(WalletsRepository.self)

    @Published var state = State.pending
    @Published var address = "..."

    private var cancellables = Set<AnyCancellable>()

    private let scanQrClicked = PassthroughSubject<Void, Never>()
    private let error = PassthroughSubject<Bool, Never>()
    var scanQrShow: AnyPublisher<Void, Never> { scanQrClicked.eraseToAnyPublisher() }
    var errorShow: AnyPublisher<Bool, Never> { error.eraseToAnyPublisher() }

    private var initStateFinished = false

    init() {
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

            self.address = self.walletsRepository.nativeWallet?.pubkey?.shortAddress ?? "..."
            self.state = $0
            if $0 != .pending {
                self.initStateFinished = true
            }
        })
        .store(in: &cancellables)
        walletsRepository.stateObservable
            .asPublisher()
            .assertNoFailure()
            .map { $0 == .error }
            .sink(receiveValue: { [weak self] hasError in
                // TODO: catch network error!
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
        analyticsManager.log(event: .receiveAddressCopied)
    }

    func scanQr() {
        scanQrClicked.send()
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
