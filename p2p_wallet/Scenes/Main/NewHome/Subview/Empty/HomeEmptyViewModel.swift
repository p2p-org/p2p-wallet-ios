import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import UIKit

final class HomeEmptyViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    private let navigation: PassthroughSubject<HomeNavigation, Never>

    private var popularCoinsTokens: [TokenMetadata] = [.usdc, .nativeSolana, /* .renBTC, */ .eth, .usdt]
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
        await HomeAccountsSynchronisationService().refresh()

        updateData()
    }

    func receiveClicked() {
        let userWalletManager = Resolver.resolve(UserWalletManager.self)
        guard let pubkey = userWalletManager.wallet?.account.publicKey
        else { return }
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
        // TODO: Should be removed
        popularCoins = popularCoinsTokens.map { token in
            PopularCoin(
                title: title(for: token),
                amount: nil,
                actionTitle: ActionType.buy.description,
                image: image(for: token)
            )
        }
    }
}

// MARK: - Model

extension HomeEmptyViewModel {
    class PopularCoin {
        let title: String
        let amount: String?
        @Published var actionTitle: String
        let image: ImageResource

        init(
            title: String,
            amount: String?,
            actionTitle: String,
            image: ImageResource
        ) {
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
    func title(for token: TokenMetadata) -> String {
        if token == .eth {
            return "Ethereum"
        } else if token == .renBTC {
            return L10n.bitcoin
        }
        return token.name
    }

    func image(for token: TokenMetadata) -> ImageResource {
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
        return .squircleSolanaIcon
    }
}
