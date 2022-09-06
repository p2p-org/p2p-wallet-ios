import Combine
import Foundation
import Resolver
import SafariServices
import SolanaSwift
import SwiftUI

final class BuyCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = BuyViewModel()
        let viewController = UIHostingController(rootView: BuyView(viewModel: viewModel))
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)

        viewModel.coordinatorIO.showDetail
            .receive(on: RunLoop.main)
            .flatMap { exchangeOutput, exchangeRate, currency in
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

        viewModel.coordinatorIO.showTokenSelect.flatMap { tokens in
            self.coordinate(
                to: BuySelectCoordinator<Token, BuySelectTokenCellView>(
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

        viewModel.coordinatorIO.showFiatSelect.flatMap { fiats in
            self.coordinate(
                to: BuySelectCoordinator<Fiat, FiatCellView>(
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

        viewModel.coordinatorIO.buy.sink(receiveValue: { [weak self] url in
            let vc = SFSafariViewController(url: url)
            vc.modalPresentationStyle = .automatic
            self?.navigationController.present(vc, animated: true)
        }).store(in: &subscriptions)

        // TODO: substitute with result subject
        return PassthroughSubject<Void, Never>().eraseToAnyPublisher()
    }
}
