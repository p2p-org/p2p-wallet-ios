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
import SolanaSwift

class HomeViewModel: ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationService
    private let walletsRepository: WalletsRepository

    @Published var state = State.pending
    @Published var address = "..."

    private var cancellables = Set<AnyCancellable>()

    private let receiveClicked = PassthroughSubject<Void, Never>()
    private let error = PassthroughSubject<Bool, Never>()
    var receiveShow: AnyPublisher<PublicKey, Never>
    var errorShow: AnyPublisher<Bool, Never> { error.eraseToAnyPublisher() }

    private var initStateFinished = false

    init() {
        let walletsRepository = Resolver.resolve(WalletsRepository.self)
        self.walletsRepository = walletsRepository
        receiveShow = receiveClicked
            .compactMap { try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) }
            .eraseToAnyPublisher()

        Publishers.CombineLatest(
            walletsRepository.statePublisher,
            walletsRepository.dataPublisher.filter { !$0.isEmpty }
        ).map { state, data -> State in
            switch state {
            case .initializing, .loading:
                return State.pending
            case .loaded, .error:
                let amount = data.reduce(0) { partialResult, wallet in partialResult + wallet.amount }
                return amount > 0 ? State.withTokens : State.empty
            }
        }
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

        walletsRepository.statePublisher
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

    func receive() {
        receiveClicked.send()
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
