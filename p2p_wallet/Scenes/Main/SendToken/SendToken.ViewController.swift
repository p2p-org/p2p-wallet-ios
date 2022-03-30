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
        // MARK: - Dependencies

        private let viewModel: SendTokenViewModelType

        // MARK: - Properties

        private var childNavigationController: UINavigationController!

        // MARK: - Handlers

        var doneHandler: (() -> Void)?

        // MARK: - Initializer

        init(viewModel: SendTokenViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.setNavigationBarHidden(true, animated: true)
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

        func popToRootViewController(animated: Bool) {
            childNavigationController.popToRootViewController(animated: animated)
        }

        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .back:
                back()
            case let .chooseTokenAndAmount(showAfterConfirmation):
                let amount = viewModel.getSelectedAmount()
                let vm = ChooseTokenAndAmount.ViewModel(
                    initialAmount: amount,
                    showAfterConfirmation: showAfterConfirmation,
                    selectedNetwork: viewModel.getSelectedNetwork(),
                    sendTokenViewModel: viewModel
                )
                let vc = ChooseTokenAndAmount.ViewController(viewModel: vm)

                if showAfterConfirmation {
                    childNavigationController?.pushViewController(vc, animated: true)
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
                childNavigationController?.pushViewController(vc, animated: true)
            case .confirmation:
                let vc = ConfirmViewController(viewModel: viewModel)
                childNavigationController?.pushViewController(vc, animated: true)
            case let .processTransaction(transaction):
                let vm = ProcessTransaction.ViewModel(processingTransaction: transaction)
                let vc = ProcessTransaction.ViewController(viewModel: vm)
                vc.doneHandler = doneHandler
                vc.makeAnotherTransactionHandler = { [weak self] in
                    guard let self = self else { return }
                    self.viewModel.cleanAllFields()
                    self.childNavigationController.popToRootViewController(animated: true)
                }
                childNavigationController?.pushViewController(vc, animated: true)
            case .chooseNetwork:
                let vc = SelectNetwork.ViewController(viewModel: viewModel)
                childNavigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
