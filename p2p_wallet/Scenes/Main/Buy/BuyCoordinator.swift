import AnalyticsManager
import Combine
import Foundation
import Resolver
import SafariServices
import SolanaSwift
import SwiftUI

final class BuyCoordinator: Coordinator<Void> {
    private var navigationController: UINavigationController!
    private let presentingViewController: UIViewController?
    private let context: Context
    private var shouldPush = true
    private var defaultToken: Token?
    private let targetTokenSymbol: String?
    @Injected private var analyticsManager: AnalyticsManager

    init(
        navigationController: UINavigationController? = nil,
        context: Context,
        defaultToken: Token? = nil,
        presentingViewController: UIViewController? = nil,
        shouldPush: Bool = true,
        targetTokenSymbol: String? = nil
    ) {
        self.navigationController = navigationController
        self.presentingViewController = presentingViewController
        self.context = context
        self.shouldPush = shouldPush
        self.defaultToken = defaultToken
        self.targetTokenSymbol = targetTokenSymbol
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = BuyViewModel(defaultToken: defaultToken, targetSymbol: targetTokenSymbol)
        let viewController = UIHostingController(rootView: BuyView(viewModel: viewModel))
        viewController.title = L10n.buy
        viewController.hidesBottomBarWhenPushed = true
        if navigationController == nil {
            navigationController = UINavigationController(rootViewController: viewController)
        }
        
        if let presentingViewController = presentingViewController {
            DispatchQueue.main.async {
                presentingViewController.show(self.navigationController, sender: nil)
            }
        } else {
            if shouldPush {
                navigationController?.pushViewController(viewController, animated: true)
            } else {
                let navigation = UINavigationController(rootViewController: viewController)
                navigationController = navigation
                navigationController?.present(navigation, animated: true)
            }
        }

        analyticsManager
            .log(event: AmplitudeEvent
                .buyScreenOpened(lastScreen: context == .fromHome ? "Main_Screen" : "Token_Screen"))

        viewController.navigationItem.largeTitleDisplayMode = .never

        viewModel.coordinatorIO.showDetail
            .receive(on: RunLoop.main)
            .flatMap { [unowned self] exchangeOutput, exchangeRate, currency, token in
                self.coordinate(to:
                    BuyTransactionDetailsCoordinator(
                        controller: navigationController,
                        model: .init(
                            price: exchangeRate,
                            purchaseCost: exchangeOutput.purchaseCost,
                            processingFee: exchangeOutput.processingFee,
                            networkFee: exchangeOutput.networkFee,
                            total: exchangeOutput.total,
                            currency: currency,
                            token: token
                        )
                    ))
            }.sink(receiveValue: { _ in })
            .store(in: &subscriptions)

        viewModel.coordinatorIO.showTokenSelect.flatMap { [unowned self] tokens in
            self.coordinate(
                to: BuySelectCoordinator<TokenCellViewItem, BuySelectTokenCellView>(
                    title: L10n.coinsToBuy,
                    controller: navigationController,
                    items: tokens,
                    selectedModel: tokens.first { $0.token.symbol == viewModel.token.symbol }
                )
            )
        }.compactMap { result in
            switch result {
            case let .result(model):
                return model.token
            default:
                return nil
            }
        }
        .assign(to: \.value, on: viewModel.coordinatorIO.tokenSelected)
        .store(in: &subscriptions)

        viewModel.coordinatorIO.showFiatSelect.flatMap { [unowned self] fiats in
            self.coordinate(
                to: BuySelectCoordinator<Fiat, FiatCellView>(
                    title: L10n.currency,
                    controller: navigationController,
                    items: fiats,
                    selectedModel: viewModel.fiat
                )
            )
        }.compactMap { result in
            switch result {
            case let .result(model):
                return model
            default:
                return nil
            }
        }
        .assign(to: \.value, on: viewModel.coordinatorIO.fiatSelected)
        .store(in: &subscriptions)

        viewModel.coordinatorIO.buy.sink(receiveValue: { [weak self, weak viewController] url in
            guard let self else { return }
            let vc = SFSafariViewController(url: url)
            vc.modalPresentationStyle = .automatic
            viewController?.present(vc, animated: true)
            viewController?.deallocatedPublisher().sink(receiveValue: { _ in
                self.analyticsManager.log(event: AmplitudeEvent.moonpayWindowClosed)
            }).store(in: &self.subscriptions)
        }).store(in: &subscriptions)

        return viewController.deallocatedPublisher().prefix(1).eraseToAnyPublisher()
    }
}

// MARK: - Context

extension BuyCoordinator {
    enum Context {
        case fromHome
        case fromToken
        case fromRenBTC
        case fromInvest

        var screenName: String {
            switch self {
            case .fromHome: return "MainScreen"
            case .fromToken: return "TokenScreen"
            case .fromRenBTC: return "RenBTCScreen"
            case .fromInvest: return "SolendScreen"
            }
        }
    }
}
