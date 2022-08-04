//
//  HomeCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

import Combine
import Foundation
import Resolver
import UIKit

final class HomeCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = Home.ViewModel()
        let emptyViewModel = HomeEmptyViewModel(
            pricesService: Resolver.resolve(),
            walletsRepository: Resolver.resolve()
        )
        let emptyVMOutput = emptyViewModel.output.coord

        navigationController.setViewControllers(
            [
                Home.ViewController(
                    viewModel: viewModel,
                    emptyViewModel: emptyViewModel
                ),
            ],
            animated: false
        )

        emptyVMOutput.topUpShow
            .sink(receiveValue: { [unowned self] in
                navigationController.present(
                    BuyTokenSelection.Scene(onTap: { [unowned self] in
                        let coordinator = BuyPreparingCoordinator(
                            navigationController: navigationController,
                            crypto: $0
                        )
                        coordinate(to: coordinator)
                    }),
                    animated: true
                )
            })
            .store(in: &subscriptions)
        emptyVMOutput.topUpCoinShow
            .sink(receiveValue: { [unowned self] in
                let coordinator = BuyPreparingCoordinator(
                    navigationController: navigationController,
                    crypto: $0
                )
                coordinate(to: coordinator)
            })
            .store(in: &subscriptions)
        emptyVMOutput.receiveRenBtcShow
            .sink(receiveValue: { [unowned self] solanaPubkey in
                let vm = ReceiveToken.SceneModel(
                    solanaPubkey: solanaPubkey,
                    solanaTokenWallet: nil,
                    isOpeningFromToken: true
                )
                let vc = ReceiveToken.ViewController(viewModel: vm, isOpeningFromToken: true)
                let navigation = UINavigationController(rootViewController: vc)
                navigationController.present(navigation, animated: true)
                vm.switchToken(.btc)
            })
            .store(in: &subscriptions)

        return Empty(completeImmediately: false)
            .eraseToAnyPublisher()
    }
}
