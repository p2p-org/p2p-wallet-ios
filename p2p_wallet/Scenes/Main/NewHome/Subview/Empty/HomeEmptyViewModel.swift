import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift
import KeyAppKitCore
import KeyAppBusiness
import KeyAppUI
import BankTransfer
import UIKit

final class HomeEmptyViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var pricesService: SolanaPriceService
    @Injected private var bankTransferService: any BankTransferService
    @Injected private var notificationService: NotificationService

    // MARK: - Properties
    private let navigation: PassthroughSubject<HomeNavigation, Never>

    private var popularCoinsTokens: [Token] = [.usdc, .nativeSolana, /*.renBTC, */.eth, .usdt]
    @Published var popularCoins = [PopularCoin]()
    @Published var banner: HomeBannerParameters
    let bannerTapped = PassthroughSubject<Void, Never>()
    private let tappedBannerSubject = PassthroughSubject<HomeNavigation, Never>()
    private let shouldShowErrorSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Initializer

    init(navigation: PassthroughSubject<HomeNavigation, Never>) {
        self.navigation = navigation
        self.banner = HomeBannerParameters(
            id: UUID().uuidString,
            backgroundColor: Asset.Colors.lightGrass.color,
            image: .homeBannerPerson,
            imageSize: CGSize(width: 198, height: 142),
            title: L10n.topUpYourAccountToGetStarted,
            subtitle: L10n.makeYourFirstDepositOrBuyCryptoWithYourCreditCardOrApplePay,
            button: HomeBannerParameters.Button(title: L10n.addMoney, isLoading: false, handler: { navigation.send(.topUp) })
        )
        super.init()
        updateData()
        bindBankTransfer()
    }

    // MARK: - Actions
    let homeAccountsSynchronisationService = HomeAccountsSynchronisationService()
    func reloadData() async {
        // refetch
        await homeAccountsSynchronisationService.refresh()
        updateData()
    }

    func buyTapped(index: Int) {
        let coin = popularCoinsTokens[index]
        analyticsManager.log(event: .mainScreenBuyToken(tokenName: coin.symbol))
        navigation.send(.topUpCoin(coin))
    }
}

private extension HomeEmptyViewModel {
    func updateData() {
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

    func bindBankTransfer() {
        bankTransferService.state
            .filter { $0.value.userId != nil && $0.value.mobileVerified }
            .receive(on: RunLoop.main)
            .compactMap { [weak self] value -> HomeBannerParameters? in
                guard let self else { return nil }

                if value.value.isIBANNotReady && !shouldShowErrorSubject.value {
                    self.shouldShowErrorSubject.send(true)
                }

                return HomeBannerParameters(
                    status: value.value.kycStatus,
                    action: { [weak self] in
                        self?.tappedBannerSubject.send(.bankTransfer)
                    },
                    isLoading: false,
                    isSmallBanner: false
                )
            }
            .assignWeak(to: \.banner, on: self)
            .store(in: &subscriptions)

        tappedBannerSubject
            .withLatestFrom(bankTransferService.state)
            .filter { !$0.isFetching }
            .receive(on: RunLoop.main)
            .sink{ [weak self] state in
                guard let self else { return }
                if state.value.isIBANNotReady {
                    self.banner.button?.isLoading = true
                    self.shouldShowErrorSubject.send(false)
                    Task { await self.bankTransferService.reload() }
                } else {
                    self.navigation.send(.bankTransfer)
                }
            }
            .store(in: &subscriptions)

        shouldShowErrorSubject
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.notificationService.showToast(title: "❌", text: L10n.somethingWentWrong) }
            .store(in: &subscriptions)

        bannerTapped
            .sink { [weak self] _ in self?.tappedBannerSubject.send(.bankTransfer) }
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

private extension SolanaPriceService {
    func fiatAmount(token: Token) -> String? {
        guard let price = getPriceFromCache(token: token, fiat: Defaults.fiat.code)?.value
        else { return nil }
        return "\(Defaults.fiat.symbol) \(price.toString(minimumFractionDigits: 2, maximumFractionDigits: 2))"
    }
}
