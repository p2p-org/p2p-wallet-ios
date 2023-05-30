//
//  HomeEmptyViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift
import KeyAppKitCore
import KeyAppBusiness

final class HomeEmptyViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var pricesService: SolanaPriceService
    @Injected private var solanaAccountsService: SolanaAccountsService
    
    // MARK: - Properties
    private let navigation: PassthroughSubject<HomeNavigation, Never>
    
    private var popularCoinsTokens: [Token] = [.usdc, .nativeSolana, /*.renBTC, */.eth, .usdt]
    @Published var popularCoins = [PopularCoin]()

    // MARK: - Initializer

    init(navigation: PassthroughSubject<HomeNavigation, Never>) {
        self.navigation = navigation
        super.init()
        updateData()
    }
    
    // MARK: - Actions

    func reloadData() async {
        // refetch
        try? await solanaAccountsService.fetch()
        
        updateData()
    }

    func receiveClicked() {
        guard let pubkey = try? PublicKey(string: solanaAccountsService.state.value.nativeWallet?.data.pubkey) else { return }
        navigation.send(.receive(publicKey: pubkey))
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
                amount: pricesService.fiatAmount(token: token),
                actionTitle: ActionType.buy.description,
                image: image(for: token)
            )
        }
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

private extension SolanaPriceService {
    func fiatAmount(token: Token) -> String? {
        guard let price = getPriceFromCache(token: token, fiat: Defaults.fiat.code)?.value
        else { return nil }
        return "\(Defaults.fiat.symbol) \(price.toString(minimumFractionDigits: 2, maximumFractionDigits: 2))"
    }
}
