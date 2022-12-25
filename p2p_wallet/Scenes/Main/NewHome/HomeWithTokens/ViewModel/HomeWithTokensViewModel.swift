//
//  HomeWithTokensViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import RxCombine
import RxSwift
import SolanaSwift
import UIKit
import SwiftyUserDefaults
import Sell

final class HomeWithTokensViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies
    
    private let walletsRepository: WalletsRepository
    @Injected private var pricesService: PricesServiceType
    @Injected private var solanaTracker: SolanaTracker
    @Injected private var notificationService: NotificationService
    @Injected private var sellDataService: any SellDataService
    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    let navigation: PassthroughSubject<HomeNavigation, Never>

    var balance: AnyPublisher<String, Never>
    var actions: AnyPublisher<[WalletActionType], Never>

    @Published var scrollOnTheTop = true

    private var wallets = [Wallet]()
    @Published var items = [Wallet]()
    @Published var hiddenItems = [Wallet]()
    @Published var tokensIsHidden: Bool
    @SwiftyUserDefault(keyPath: \.isSellAvailable, options: .cached)
    static var cachedIsSellAvailable

    // MARK: - Initializer

    init(navigation: PassthroughSubject<HomeNavigation, Never>) {
        self.navigation = navigation

        let walletsRepository = Resolver.resolve(WalletsRepository.self)
        tokensIsHidden = !walletsRepository.isHiddenWalletsShown.value

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
        self.walletsRepository = walletsRepository
        
        var actns = [WalletActionType.buy, .receive, .send, .swap]
        if Self.cachedIsSellAvailable ?? false {
            actns = [WalletActionType.buy, .receive, .send, .cashOut]
        }
        actions = Just(actns).eraseToAnyPublisher()
        
        super.init()
        
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
            .store(in: &subscriptions)

        if available(.solanaNegativeStatus) {
            solanaTracker.unstableSolana
                .sink(receiveValue: { [weak self] in
                    self?.notificationService.showToast(
                        title: "😴",
                        text: L10n.solanaHasSomeProblems,
                        withAutoHidden: false
                    )
                })
                .store(in: &subscriptions)
        }
        if available(.sellScenarioEnabled) {
            Task {
                Self.cachedIsSellAvailable = await sellDataService.isAvailable()
            }
        }
    }

    func viewAppeared() {
        if available(.solanaNegativeStatus) {
            solanaTracker.startTracking()
        }

        analyticsManager.log(
            event: AmplitudeEvent.mainScreenWalletsOpen(isSellEnabled: Self.cachedIsSellAvailable ?? false)
        )
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
            guard let pubkey = try? PublicKey(string: walletsRepository.nativeWallet?.pubkey)
            else { return }
            navigation.send(.receive(publicKey: pubkey))
        case .buy:
            navigation.send(.buy)
        case .send:
            navigation.send(.send)
        case .swap:
            navigation.send(.swap)
        case .cashOut:
            navigation.send(.cashOut)
        }
    }

    func earn() {
        navigation.send(.earn)
    }

    func tokenClicked(wallet: Wallet) {
        guard let pubKey = wallet.pubkey else { return }
        navigation.send(.wallet(pubKey: pubKey, tokenSymbol: wallet.token.symbol))
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

    func sellTapped() {
        navigation.send(.cashOut)
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
