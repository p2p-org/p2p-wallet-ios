import Combine
import Foundation
import Resolver
import SafariServices
import SolanaSwift
import SwiftUI

final class BuyCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private var vcPresentedPercentage = PassthroughSubject<CGFloat, Never>()
    private var shouldPush = true

    init(navigationController: UINavigationController, shouldPush: Bool = true) {
        self.navigationController = navigationController
        self.shouldPush = shouldPush
    }

    override func start() -> AnyPublisher<Void, Never> {
        let result = PassthroughSubject<Void, Never>()
        let viewModel = BuyViewModel()
        let viewController = UIHostingController(rootView: BuyView(viewModel: viewModel))
        viewController.hidesBottomBarWhenPushed = true
        navigationController.interactivePopGestureRecognizer?.addTarget(self, action: #selector(onGesture))
        if shouldPush {
            navigationController.pushViewController(viewController, animated: true)
        } else {
            navigationController.present(viewController, animated: true)
        }

        viewController.onClose = {
            result.send()
        }

        viewModel.coordinatorIO.showDetail
            .receive(on: RunLoop.main)
            .flatMap { [unowned self] exchangeOutput, exchangeRate, currency in
                self.coordinate(to:
                    TransactionDetailsCoordinator(
                        navigationController: self.navigationController,
                        model: .init(
                            solPrice: exchangeRate,
                            solPurchaseCost: exchangeOutput.purchaseCost,
                            processingFee: exchangeOutput.processingFee,
                            networkFee: exchangeOutput.networkFee,
                            total: exchangeOutput.total,
                            currency: currency
                        )
                    ))
            }.sink { _ in }.store(in: &subscriptions)

        viewModel.coordinatorIO.showTokenSelect.flatMap { [unowned self] tokens in
            self.coordinate(
                to: BuySelectCoordinator<Token, BuySelectTokenCellView>(
                    title: L10n.coinsToBuy,
                    navigationController: self.navigationController,
                    items: tokens,
                    contentHeight: 395,
                    selectedModel: viewModel.token
                )
            )
        }.sink(receiveValue: { result in
            switch result {
            case let .result(model):
                viewModel.coordinatorIO.tokenSelected.send(model)
            default:
                return
            }
        }).store(in: &subscriptions)

        viewModel.coordinatorIO.showFiatSelect.flatMap { [unowned self] fiats in
            self.coordinate(
                to: BuySelectCoordinator<Fiat, FiatCellView>(
                    title: L10n.currency,
                    navigationController: self.navigationController,
                    items: fiats,
                    contentHeight: 436,
                    selectedModel: viewModel.fiat
                )
            )
        }.sink(receiveValue: { result in
            switch result {
            case let .result(model):
                viewModel.coordinatorIO.fiatSelected.send(model)
            default:
                return
            }
        }).store(in: &subscriptions)

        vcPresentedPercentage.eraseToAnyPublisher()
            .sink(receiveValue: { val in
                viewModel.coordinatorIO.navigationSlidingPercentage.send(val)
            })
            .store(in: &subscriptions)

        viewModel.coordinatorIO.buy.sink(receiveValue: { [weak self] url in
            let vc = SFSafariViewController(url: url)
            vc.modalPresentationStyle = .automatic
            self?.navigationController.present(vc, animated: true)
        }).store(in: &subscriptions)

        return result.prefix(1).eraseToAnyPublisher()
    }

    // MARK: -

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
