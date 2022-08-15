//
//  ChooseRecipientAndNetworkCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 18.04.2022.
//

import Combine
import Foundation
import UIKit

extension SendToken.ChooseRecipientAndNetwork {
    final class Coordinator {
        private let viewModel: SendTokenChooseRecipientAndNetworkViewModelType
        private weak var navigationController: UINavigationController?

        private lazy var addressVC = SelectAddress.ViewController(
            viewModel: viewModel.createSelectAddressViewModel()
        )

        private var subscriptions = [AnyCancellable]()

        init(
            viewModel: SendTokenChooseRecipientAndNetworkViewModelType,
            navigationController: UINavigationController
        ) {
            // clearing recipient on init
            viewModel.setRecipient(nil)
            self.viewModel = viewModel
            self.navigationController = navigationController
            bind()
        }

        private func bind() {
            Publishers.CombineLatest(
                viewModel.walletPublisher,
                viewModel.amountPublisher
            )
                .map { wallet, amount -> String in
                    let amount = amount ?? 0
                    let symbol = wallet?.token.symbol ?? ""
                    return L10n.send(amount.toString(maximumFractionDigits: 9), symbol)
                }
                .sink { [weak self] in
                    self?.addressVC.navigationItem.title = $0
                }
                .store(in: &subscriptions)

            viewModel.navigatableScenePublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)
        }

        func start() {
            navigationController?.pushViewController(addressVC, animated: true)
        }

        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .chooseNetwork:
                let vc = SendToken.SelectNetwork.ViewController(viewModel: viewModel)
                navigationController?.pushViewController(vc, animated: true)
            case .backToConfirmation:
                navigationController?.popToViewController(
                    ofClass: SendToken.ConfirmViewController.self,
                    animated: true
                )
            }
        }
    }
}
