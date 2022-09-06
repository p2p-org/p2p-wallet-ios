import Combine
import Foundation
import Resolver
import SolanaSwift
import SwiftUI

final class BuyCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let fiats = [Fiat.usd, Fiat.eur, Fiat.gbp]
        let tokens = [Token.nativeSolana, Token.usdc]

        let viewModel = NewBuyViewModel()
        let viewController = UIHostingController(rootView: NewBuyView(viewModel: viewModel))
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)

        viewModel.coordinator.showDetail.flatMap { _ in
            self.coordinate(to:
                TransactionDetailsCoordinator(
                    navigationController: self.navigationController,
                    model: .init(
                        solPrice: 22.1,
                        solPurchaseCost: 22.3,
                        processingFee: 10,
                        networkFee: 1,
                        total: 123.2,
                        currency: .usd
                    )
                ))
        }.sink { _ in }.store(in: &subscriptions)

//        viewModel.coordinator.showTokenSelect.flatMap { _ in
//            self.coordinate(
//                to: BuySelectCoordinator<Token, BuySelectTokenCellView>(
//                    navigationController: self.navigationController,
//                    items: tokens,
//                    contentHeight: 395,
//                    selectedModel: viewModel.token
//                )
//            )
//        }.sink(receiveValue: { result in
//            switch result {
//            case let .result(model):
//                viewModel.coordinatorIO.tokenSelected.send(model)
//            default:
//                return
//            }
//        }).store(in: &subscriptions)
//
//        viewModel.coordinatorIO.showFiatSelect.flatMap { _ in
//            self.coordinate(
//                to: BuySelectCoordinator<Fiat, FiatCellView>(
//                    navigationController: self.navigationController,
//                    items: fiats,
//                    contentHeight: 436,
//                    selectedModel: viewModel.fiat
//                )
//            )
//        }.sink(receiveValue: { result in
//            switch result {
//            case let .result(model):
//                viewModel.coordinatorIO.fiatSelected.send(model)
//            default:
//                return
//            }
//        }).store(in: &subscriptions)

        // TODO: substitute with result subject
        return PassthroughSubject<Void, Never>().eraseToAnyPublisher()
    }
}
