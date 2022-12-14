//
//  HomeWithTokensViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import Combine
import Foundation
import Resolver
import RxCombine
import RxSwift
import SolanaSwift
import UIKit

class HomeWithTokensViewModel: ObservableObject {
    private let walletsRepository: WalletsRepository
    private let pricesService = Resolver.resolve(PricesServiceType.self)
    @Injected private var solanaTracker: SolanaTracker
    @Injected private var notificationService: NotificationService

    private let buyClicked = PassthroughSubject<Void, Never>()
    private let receiveClicked = PassthroughSubject<Void, Never>()
    private let sendClicked = PassthroughSubject<Void, Never>()
    private let swapClicked = PassthroughSubject<Void, Never>()
    private let earnClicked = PassthroughSubject<Void, Never>()
    private let walletClicked = PassthroughSubject<(pubKey: String, tokenSymbol: String), Never>()
    let buyShow: AnyPublisher<Void, Never>
    let receiveShow: AnyPublisher<PublicKey, Never>
    let sendShow: AnyPublisher<Void, Never>
    let swapShow: AnyPublisher<Void, Never>
    let earnShow: AnyPublisher<Void, Never>
    let walletShow: AnyPublisher<(pubKey: String, tokenSymbol: String), Never>

    var actions: AnyPublisher<[WalletActionType], Never>
    var balance: AnyPublisher<String, Never>

    @Published var scrollOnTheTop = true

    private var wallets = [Wallet]()
    @Published var items = [Wallet]()
    @Published var hiddenItems = [Wallet]()

    @Published var tokensIsHidden: Bool

    private var cancellables = Set<AnyCancellable>()

    init(walletsRepository: WalletsRepository = Resolver.resolve()) {
        self.walletsRepository = walletsRepository

        tokensIsHidden = !walletsRepository.isHiddenWalletsShown.value

        buyShow = buyClicked.eraseToAnyPublisher()
        receiveShow = receiveClicked
            .compactMap { try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) }
            .eraseToAnyPublisher()
        sendShow = sendClicked.eraseToAnyPublisher()
        swapShow = swapClicked.eraseToAnyPublisher()
        walletShow = walletClicked.eraseToAnyPublisher()
        earnShow = earnClicked.eraseToAnyPublisher()
        actions = Just([WalletActionType.buy, .receive, .send, .swap]).eraseToAnyPublisher()

        balance = Observable.zip(walletsRepository.dataObservable, walletsRepository.stateObservable)
            .filter { $0.1 == .loaded }
            .map { data, _ in
                let data = data ?? []
                let equityValue = data.reduce(0) { $0 + $1.amountInCurrentFiat }
                return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
            }
            .asPublisher()
            .assertNoFailure()
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
        walletsRepository.dataObservable
            .asPublisher()
            .assertNoFailure()
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] wallets in
                guard let self = self, var wallets = wallets else { return }
                wallets = wallets.filter { !$0.isNFTToken }
                self.wallets = wallets
                let items = wallets.map { ($0, $0.isHidden) }
                self.items = items.filter { !$0.1 }.map(\.0)
                self.hiddenItems = items.filter(\.1).map(\.0)
            })
            .store(in: &cancellables)

        if available(.solanaNegativeStatus) {
            solanaTracker.unstableSolana
                .sink(receiveValue: { [weak self] in
                    self?.notificationService.showToast(
                        title: "😴",
                        text: L10n.solanaHasSomeProblems,
                        withAutoHidden: false
                    )
                })
                .store(in: &cancellables)
        }
    }

    func viewAppeared() {
        if available(.solanaNegativeStatus) {
            solanaTracker.startTracking()
        }
    }

    func reloadData() async {
        walletsRepository.reload()
        _ = try? await walletsRepository.stateObservable
            .asPublisher()
            .assertNoFailure()
            .filter { $0 == .loaded || $0 == .error }
            .eraseToAnyPublisher()
            .async()
    }

    func actionClicked(_ action: WalletActionType) {
        switch action {
        case .receive:
            receiveClicked.send()
        case .buy:
            buyClicked.send()
        case .send:
            sendClicked.send()
        case .swap:
            swapClicked.send()
        }
    }

    func earn() {
        earnClicked.send()
    }

    func tokenClicked(wallet: Wallet) {
        guard let pubKey = wallet.pubkey else { return }
        walletClicked.send((pubKey: pubKey, tokenSymbol: wallet.token.symbol))
    }

    func scrollToTop() {
        scrollOnTheTop = true
    }

    func toggleTokenVisibility(wallet: Wallet) {
        walletsRepository.toggleWalletVisibility(wallet)
    }

    func toggleHiddenTokensVisibility() {
        walletsRepository.toggleIsHiddenWalletShown()
        tokensIsHidden.toggle()
    }
}

extension Wallet: Identifiable {
    public var id: String {
        return name + pubkey
    }
}

extension Wallet {
    var isNFTToken: Bool {
        // Hide NFT TODO: $0.token.supply == 1 is also a condition for NFT but skipped atm
        token.decimals == 0
    }
}
