//
//  SendTokenCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 18.04.2022.
//

import Combine
import Foundation

extension SendToken {
    @MainActor
    final class Coordinator {
        private let viewModel: SendTokenViewModelType
        private weak var navigationController: UINavigationController?

        private var coordinator: ChooseRecipientAndNetwork.Coordinator?
        private var subscriptions = [AnyCancellable]()

        var doneHandler: (() -> Void)?

        init(
            viewModel: SendTokenViewModelType,
            navigationController: UINavigationController?
        ) {
            self.viewModel = viewModel
            self.navigationController = navigationController
            bind()
        }

        deinit {
            print("\(String(describing: self)) deinited")
        }

        private func bind() {
            viewModel.navigatableScenePublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)
        }

        // MARK: - Navigation

        @discardableResult
        func start(hidesBottomBarWhenPushed: Bool, push: Bool = true) -> UIViewController {
            pushChooseToken(
                showAfterConfirmation: false,
                hidesBottomBarWhenPushed: hidesBottomBarWhenPushed,
                push: push
            )
        }

        @discardableResult
        private func pushChooseToken(
            showAfterConfirmation: Bool,
            hidesBottomBarWhenPushed: Bool,
            push: Bool = true
        ) -> UIViewController {
            let amount = viewModel.amount
            let vm = ChooseTokenAndAmount.ViewModel(
                initialAmount: amount,
                showAfterConfirmation: showAfterConfirmation,
                selectedNetwork: viewModel.getSelectedNetwork(),
                sendTokenViewModel: viewModel
            )
            let vc = ChooseTokenAndAmount.ViewController(
                viewModel: vm,
                hidesBottomBarWhenPushed: hidesBottomBarWhenPushed
            )
            if let navigationController = navigationController {
                if push {
                    navigationController.pushViewController(vc, animated: true)
                    return vc
                } else {
                    let navigation = UINavigationController(rootViewController: vc)
                    navigationController.present(navigation, animated: true)
                    self.navigationController = navigation
                    return navigation
                }
            } else {
                let navigationController = UINavigationController(rootViewController: vc)
                self.navigationController = navigationController
                return navigationController
            }
        }

        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .back:
                navigationController?.popViewController(animated: true)
            case let .chooseTokenAndAmount(showAfterConfirmation):
                pushChooseToken(showAfterConfirmation: showAfterConfirmation, hidesBottomBarWhenPushed: true)
            case let .chooseRecipientAndNetwork(showAfterConfirmation, preSelectedNetwork, maxWasClicked):
                guard let navigationController = navigationController else { return }

                let vm = ChooseRecipientAndNetwork.ViewModel(
                    showAfterConfirmation: showAfterConfirmation,
                    preSelectedNetwork: preSelectedNetwork,
                    sendTokenViewModel: viewModel,
                    relayMethod: viewModel.relayMethod
                )
                viewModel.maxWasClicked = maxWasClicked
                coordinator = ChooseRecipientAndNetwork.Coordinator(
                    viewModel: vm,
                    navigationController: navigationController
                )
                coordinator?.start()
            case .confirmation:
                let vc = ConfirmViewController(viewModel: viewModel)
                navigationController?.pushViewController(vc, animated: true)
            case let .processTransaction(transaction):
                navigationController?.popToViewController(
                    ofClass: ChooseTokenAndAmount.ViewController.self,
                    animated: false
                )

                let vm = ProcessTransaction.ViewModel(processingTransaction: transaction)
                let vc = ProcessTransaction.ViewController(viewModel: vm)
                vc.doneHandler = { [weak self] in
                    self?.navigationController?.popToRootViewController(animated: true)
                    self?.doneHandler?()
                }
                vc.makeAnotherTransactionHandler = { [weak self] in
                    guard let self = self else { return }
                    self.viewModel.cleanAllFields()
                    self.navigationController?.popToRootViewController(animated: true)
                }
                navigationController?.pushViewController(vc, animated: true)
            case .chooseNetwork:
                let vc = SelectNetwork.ViewController(viewModel: viewModel)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
