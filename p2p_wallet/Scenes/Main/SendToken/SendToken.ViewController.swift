//
//  SendToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import BEPureLayout
import Foundation
import RxSwift
import UIKit

extension SendToken {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Dependencies

        private let viewModel: SendTokenViewModelType

        // MARK: - Properties

        private var childNavigationController: UINavigationController!

        // MARK: - Initializer

        init(viewModel: SendTokenViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()
            view.onTap { [weak self] in
                self?.view.endEditing(true)
            }
        }

        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)

            viewModel.loadingStateDriver
                .drive(view.rx.loadableState { [weak self] in
                    self?.viewModel.reload()
                })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .back:
                back()
            case let .chooseTokenAndAmount(showAfterConfirmation):
                let vm = ChooseTokenAndAmount.ViewModel(
                    initialAmount: viewModel.getSelectedAmount(),
                    showAfterConfirmation: showAfterConfirmation,
                    selectedNetwork: viewModel.getSelectedNetwork(),
                    sendTokenViewModel: viewModel
                )
                let vc = ChooseTokenAndAmount.ViewController(viewModel: vm)

                if showAfterConfirmation {
                    childNavigationController.pushViewController(vc, animated: true)
                } else {
                    childNavigationController = .init(rootViewController: vc)
                    add(child: childNavigationController)
                }
            case let .chooseRecipientAndNetwork(showAfterConfirmation, preSelectedNetwork):
                let vm = ChooseRecipientAndNetwork.ViewModel(
                    showAfterConfirmation: showAfterConfirmation,
                    preSelectedNetwork: preSelectedNetwork,
                    sendTokenViewModel: viewModel,
                    relayMethod: viewModel.relayMethod
                )
                let vc = ChooseRecipientAndNetwork.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case .confirmation:
                let vc = ConfirmViewController(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            case let .processTransaction(transaction):
                let vm = ProcessTransaction.ViewModel(processingTransaction: transaction)
                let vc = ProcessTransaction.ViewController(viewModel: vm)
                vc.backCompletion = { [weak self] in
                    guard let self = self else { return }
                    self.viewModel.cleanAllFields()
                    if self.viewModel.canGoBack {
                        self.back()
                    } else {
                        self.childNavigationController.popToRootViewController(animated: true)
                    }
                }
                vc.makeAnotherTransactionHandler = { [weak self] in
                    guard let self = self else { return }
                    self.viewModel.cleanAllFields()
                    self.childNavigationController.popToRootViewController(animated: true)
                }
                childNavigationController.pushViewController(vc, animated: true)
            case .chooseNetwork:
                let vc = SelectNetwork.ViewController(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            }
        }
    }
}
