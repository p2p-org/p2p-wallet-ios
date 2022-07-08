//
//  ChooseRecipientAndNetworkCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 18.04.2022.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

extension SendToken.ChooseRecipientAndNetwork {
    final class Coordinator {
        private let viewModel: SendTokenChooseRecipientAndNetworkViewModelType
        private weak var navigationController: UINavigationController?

        private lazy var addressVC = SelectAddress.ViewController(
            viewModel: viewModel.createSelectAddressViewModel()
        )

        private let disposeBag = DisposeBag()

        init(
            viewModel: SendTokenChooseRecipientAndNetworkViewModelType,
            navigationController: UINavigationController
        ) {
            // clearing recipient on init
            viewModel.recipientSubject.accept(nil)
            self.viewModel = viewModel
            self.navigationController = navigationController
            bind()
        }

        private func bind() {
            Driver.combineLatest(
                viewModel.walletDriver,
                viewModel.amountDriver
            )
                .map { wallet, amount -> String in
                    let amount = amount ?? 0
                    let symbol = wallet?.token.symbol ?? ""
                    return L10n.send(amount.toString(maximumFractionDigits: 9), symbol)
                }
                .drive(onNext: { [weak self] in
                    self?.addressVC.navigationItem.title = $0
                })
                .disposed(by: disposeBag)

            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
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
