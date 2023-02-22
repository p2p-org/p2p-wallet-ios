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
    @Injected private var accountStorage: AccountStorageType
    @Injected private var nameStorage: NameStorageType
    @Injected private var createNameService: CreateNameService
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

        Publishers.CombineLatest(
            walletsRepository.statePublisher,
            walletsRepository.dataPublisher
        ).map { state, data -> (State, Double?) in
            switch state {
            case .initializing, .loading:
                return (State.pending, nil)
            case .loaded, .error:
                let fiatAmount = data.totalAmountInCurrentFiat
                return (fiatAmount > 0 ? State.withTokens : State.empty, fiatAmount)
            }
        }
        .sink(receiveValue: { [weak self] state, amount in
            guard let self = self else { return }
            if self.initStateFinished, state == .pending { return }

            self.updateAddressIfNeeded()
            self.state = state
            if state != .pending {
                self.initStateFinished = true
                self.analyticsManager.log(parameter: .userHasPositiveBalance(amount > 0))
                if let amount = amount {
                    let formatted = round(amount * 100) / 100.0
                    self.analyticsManager.log(parameter: .userAggregateBalance(formatted))
                }
            }
        })
        .store(in: &cancellables)

        walletsRepository.statePublisher
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

        bind()
    }

    func copyToClipboard() {
        clipboardManager.copyToClipboard(walletsRepository.nativeWallet?.pubkey ?? "")
        notificationsService.showToast(title: "🖤", text: L10n.addressWasCopiedToClipboard, haptic: true)
        analyticsManager.log(event: .mainCopyAddress)
    }

    func updateAddressIfNeeded() {
        if let name = nameStorage.getName(), !name.isEmpty {
            address = "\(name).key"
        } else if let address = accountStorage.account?.publicKey.base58EncodedString.shortAddress {
            self.address = address
        }
    }
}

private extension HomeViewModel {
    func bind() {
        createNameService.createNameResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSuccess in
                guard isSuccess else { return }
                self?.updateAddressIfNeeded()
            }
            .store(in: &cancellables)
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
