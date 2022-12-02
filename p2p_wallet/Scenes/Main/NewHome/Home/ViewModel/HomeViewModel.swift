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

class HomeViewModel: BaseViewModel, ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationService
    @Injected private var accountStorage: AccountStorageType
    @Injected private var nameStorage: NameStorageType
    @Injected private var createNameService: CreateNameService
    private let walletsRepository: WalletsRepository

    @Published var state = State.pending
    @Published var address = ""

    private let error = PassthroughSubject<Bool, Never>()
    var errorShow: AnyPublisher<Bool, Never> { error.eraseToAnyPublisher() }

    private var initStateFinished = false

    override init() {
        let walletsRepository = Resolver.resolve(WalletsRepository.self)
        self.walletsRepository = walletsRepository
        
        super.init()
        address = accountStorage.account?.publicKey.base58EncodedString.shortAddress ?? ""
        
        Publishers.CombineLatest(
            walletsRepository.statePublisher,
            walletsRepository.dataPublisher.filter { !$0.isEmpty }
        ).map { state, data -> (State, Double?) in
            switch state {
            case .initializing, .loading:
                return (State.pending, nil)
            case .loaded, .error:
                let fiatAmount = data.reduce(0) { $0 + $1.amountInCurrentFiat }
                return (fiatAmount > 0 ? State.withTokens : State.empty, fiatAmount)
            }
        }
        .assertNoFailure()
        .receive(on: RunLoop.main)
        .sink(receiveValue: { [weak self] state, amount in
            guard let self = self else { return }
            if self.initStateFinished, state == .pending { return }

            self.updateAddressIfNeeded()
            self.state = state
            if state != .pending {
                self.initStateFinished = true
                self.analyticsManager.setIdentifier(AmplitudeIdentifier.userHasPositiveBalance(positive: amount > 0))
                self.analyticsManager.log(event: AmplitudeEvent.userHasPositiveBalance(positive: amount > 0))
                if let amount = amount {
                    let formatted = round(amount * 100) / 100.0
                    self.analyticsManager.setIdentifier(AmplitudeIdentifier.userAggregateBalance(balance: formatted))
                    self.analyticsManager.log(event: AmplitudeEvent.userAggregateBalance(balance: formatted))
                }
            }
        })
        .store(in: &subscriptions)

        walletsRepository.statePublisher
            .assertNoFailure()
            .map { $0 == .error }
            .sink(receiveValue: { [weak self] hasError in
                if hasError, self?.walletsRepository.getError() != nil {
                    self?.error.send(true)
                } else {
                    self?.error.send(false)
                }
            })
            .store(in: &subscriptions)

        walletsRepository.reload()

        bind()
    }

    func copyToClipboard() {
        if let name = nameStorage.getName(), !name.isEmpty {
            clipboardManager.copyToClipboard(
                "\(name.withNameServiceDomain()) \(walletsRepository.nativeWallet?.pubkey ?? "")"
            )
        } else {
            clipboardManager.copyToClipboard(walletsRepository.nativeWallet?.pubkey ?? "")
        }
        notificationsService.showToast(title: "🖤", text: L10n.addressWasCopiedToClipboard, haptic: true)
        analyticsManager.log(event: AmplitudeEvent.mainCopyAddress)
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
            .receive(on: RunLoop.main)
            .sink { [weak self] isSuccess in
                guard isSuccess else { return }
                self?.updateAddressIfNeeded()
            }
            .store(in: &subscriptions)
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
