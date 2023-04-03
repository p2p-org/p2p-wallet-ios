//
//  HomeEmptyViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import RenVMSwift
import Resolver
import SolanaSwift

final class HomeEmptyViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var pricesService: PricesServiceType
    
    // MARK: - Properties
    private var cancellable: AnyCancellable?
    private let navigation: PassthroughSubject<HomeNavigation, Never>
    
    private var popularCoinsTokens: [Token] = [.usdc, .nativeSolana, /*.renBTC, */.eth, .usdt]
    @Published var popularCoins = [PopularCoin]()

    // MARK: - Initializer

    init(navigation: PassthroughSubject<HomeNavigation, Never>) {
        self.navigation = navigation
        super.init()
        updateData()
        bind()
    }
    
    // MARK: - Actions

    func reloadData() async {
        walletsRepository.reload()

        let tokensWithoutPrices = popularCoinsTokens.filter { pricesService.currentPrice(mint: $0.address) == nil }
        if !tokensWithoutPrices.isEmpty {
            pricesService.fetchPrices(tokens: tokensWithoutPrices, toFiat: Defaults.fiat)
        }

        return await withCheckedContinuation { continuation in
            cancellable = walletsRepository.statePublisher
                .sink(receiveValue: { [weak self] in
                    if $0 == .loaded || $0 == .error {
                        self?.updateData()
                        continuation.resume()
                        self?.cancellable = nil
                    }
                })
        }
    }

    func receiveClicked() {
        guard let solanaPubkey = try? PublicKey(string: walletsRepository.nativeWallet?.pubkey) else { return }
        navigation.send(.receive(publicKey: solanaPubkey))
    }
    
    func buyTapped(index: Int) {
        let coin = popularCoinsTokens[index]
        analyticsManager.log(event: .mainScreenBuyToken(tokenName: coin.symbol))
        navigation.send(.topUpCoin(coin))
    }
}

private extension HomeEmptyViewModel {
    private func updateData() {
        popularCoins = popularCoinsTokens.map { token in
            PopularCoin(
                id: token.symbol,
                title: title(for: token),
                amount: pricesService.fiatAmount(mint: token.address),
                actionTitle: ActionType.buy.description,
                image: image(for: token)
            )
        }
    }

    private func bind() {
        pricesService.currentPricesPublisher
            .sink { [weak self] _ in
                self?.updateData()
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Model

extension HomeEmptyViewModel {
    class PopularCoin {
        let id: String
        let title: String
        let amount: String?
        @Published var actionTitle: String
        let image: UIImage

        init(
            id: String,
            title: String,
            amount: String?,
            actionTitle: String,
            image: UIImage
        ) {
            self.id = id
            self.title = title
            self.amount = amount
            self.actionTitle = actionTitle
            self.image = image
        }
    }

    enum ActionType {
        case buy
        case receive

        fileprivate var description: String {
            switch self {
            case .buy:
                return L10n.buy
            case .receive:
                return L10n.receive
            }
        }
    }
}

extension HomeEmptyViewModel {
    func title(for token: Token) -> String {
        if token == .eth {
            return "Ethereum"
        } else if token == .renBTC {
            return L10n.bitcoin
        }
        return token.name
    }

    func image(for token: Token) -> UIImage {
        if token == .nativeSolana {
            return .solanaIcon
        }
        if token == .usdc {
            return .usdcIcon
        }
        if token == .usdt {
            return .usdtIcon
        }
        if token == .eth {
            return .ethereumIcon
        }
        if token == .renBTC {
            return .bitcoinIcon
        }
        return token.image ?? .squircleSolanaIcon
    }
}

private extension PricesServiceType {
    func fiatAmount(mint: String) -> String? {
        guard let price = currentPrice(mint: mint)?.value else { return nil }
        return "\(Defaults.fiat.symbol) \(price.toString(minimumFractionDigits: 2, maximumFractionDigits: 2))"
    }
}
