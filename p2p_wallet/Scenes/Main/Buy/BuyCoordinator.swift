import AnalyticsManager
import Combine
import Foundation
import Resolver
import SafariServices
import SolanaSwift
import SwiftUI

final class BuyCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let context: Context
    private var shouldPush = true

    private let vcPresentedPercentage = PassthroughSubject<CGFloat, Never>()
    @Injected private var analyticsManager: AnalyticsManager

    init(
        navigationController: UINavigationController,
        context: Context,
        shouldPush: Bool = true
    ) {
        self.navigationController = navigationController
        self.context = context
        self.shouldPush = shouldPush
    }

    override func start() -> AnyPublisher<Void, Never> {
        let result = PassthroughSubject<Void, Never>()
        let viewModel = BuyViewModel()
        let viewController = UIHostingController(rootView: BuyView(viewModel: viewModel))
        viewController.hidesBottomBarWhenPushed = true
        if shouldPush {
            navigationController.interactivePopGestureRecognizer?.addTarget(self, action: #selector(onGesture))
            navigationController.pushViewController(viewController, animated: true)
        } else {
            navigationController.present(UINavigationController(rootViewController: viewController), animated: true)
        }
        analyticsManager.log(event: .buyScreenShowed(fromScreen: context == .fromHome ? "MainScreen" : "TokenScreen"))

        viewController.onClose = {
            result.send()
        }

        viewModel.coordinatorIO.showDetail
            .sink(receiveValue: { [unowned self] exchangeOutput, exchangeRate, currency in
                coordinate(to:
                    TransactionDetailsCoordinator(
                        controller: viewController,
                        model: .init(
                            solPrice: exchangeRate,
                            solPurchaseCost: exchangeOutput.purchaseCost,
                            processingFee: exchangeOutput.processingFee,
                            networkFee: exchangeOutput.networkFee,
                            total: exchangeOutput.total,
                            currency: currency
                        )
                    ))
                analyticsManager.log(event: .buyTotalShowed)
            })
            .store(in: &subscriptions)

        viewModel.coordinatorIO.showTokenSelect.flatMap { [unowned self] tokens in
            self.coordinate(
                to: BuySelectCoordinator<Token, BuySelectTokenCellView>(
                    title: L10n.coinsToBuy,
                    controller: viewController,
                    items: tokens,
                    contentHeight: 395,
                    selectedModel: viewModel.token
                )
            ).eraseToAnyPublisher()
        }.compactMap { result in
            switch result {
            case let .result(model):
                return model
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
                    controller: viewController,
                    items: fiats,
                    contentHeight: 436,
                    selectedModel: viewModel.fiat
                )
            ).eraseToAnyPublisher()
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

        vcPresentedPercentage.eraseToAnyPublisher()
            .sink(receiveValue: { val in
                viewModel.coordinatorIO.navigationSlidingPercentage.send(val)
            })
            .store(in: &subscriptions)

        viewModel.coordinatorIO.buy.sink(receiveValue: { [weak self] url in
            let vc = SFSafariViewController(url: url)
            vc.modalPresentationStyle = .automatic
            self?.navigationController.present(vc, animated: true)

            vc.onClose = { [weak self] in
                self?.analyticsManager.log(event: .moonPayWindowClosed)
            }
        }).store(in: &subscriptions)

        return result.prefix(1).eraseToAnyPublisher()
    }

    // MARK: - Gesture

    private var currentTransitionCoordinator: UIViewControllerTransitionCoordinator?

    @objc private func onGesture(sender: UIGestureRecognizer) {
        switch sender.state {
        case .began, .changed:
            if let ct = navigationController.transitionCoordinator {
                currentTransitionCoordinator = ct
            }
        case .cancelled, .ended:
            //            currentTransitionCoordinator = nil
            break
        case .possible, .failed:
            break
        @unknown default:
            break
        }
//        if let currentTransitionCoordinator = currentTransitionCoordinator {
//            vcPresentedPercentage.send(currentTransitionCoordinator.percentComplete)
//        }
        vcPresentedPercentage.send(navigationController.transitionCoordinator?.percentComplete ?? 1)
    }
}

// MARK: - Context

extension BuyCoordinator {
    enum Context {
        case fromHome
        case fromToken
    }
}
