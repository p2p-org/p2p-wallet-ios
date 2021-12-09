//
//  SendToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import UIKit
import BEPureLayout
import RxSwift

protocol SendTokenScenesFactory {
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool, handler: WalletDidSelectHandler) -> ChooseWallet.ViewController
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
}

extension SendToken {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: SendTokenViewModelType
        private let scenesFactory: SendTokenScenesFactory
        
        // MARK: - Properties
        private var childNavigationController: BENavigationController!
        
        // MARK: - Initializer
        init(viewModel: SendTokenViewModelType, scenesFactory: SendTokenScenesFactory) {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .back:
                back()
            case .chooseTokenAndAmount(let showAfterConfirmation):
                let vm = ChooseTokenAndAmount.ViewModel(
                    sendTokenViewModel: viewModel,
                    initialAmount: viewModel.getSelectedAmount(),
                    showAfterConfirmation: showAfterConfirmation
                )
                let vc = ChooseTokenAndAmount.ViewController(viewModel: vm, scenesFactory: scenesFactory)
                
                if showAfterConfirmation {
                    childNavigationController.pushViewController(vc, animated: true)
                } else {
                    childNavigationController = BENavigationController(rootViewController: vc)
                    add(child: childNavigationController)
                }
            case .chooseRecipientAndNetwork:
                let vm = ChooseRecipientAndNetwork.ViewModel(sendTokenViewModel: viewModel)
                let vc = ChooseRecipientAndNetwork.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case .confirmation:
                let vc = ConfirmViewController(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            case .processTransaction(let request, let transactionType):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
            case .chooseNetwork:
                let vc = SendToken.SelectNetworkViewController(
                    selectableNetworks: viewModel.getSelectableNetworks(),
                    prices: viewModel.getSOLAndRenBTCPrices(),
                    selectedNetwork: viewModel.getSelectedNetwork(),
                    selectNetworkCompletion: {[weak self] network in
                        self?.viewModel.selectNetwork(network)
                    }
                )
                show(vc, sender: nil)
            }
        }
    }
}

extension SendToken.ViewController: ProcessTransactionViewControllerDelegate {
    func processTransactionViewControllerDidComplete(_ vc: UIViewController) {
        vc.dismiss(animated: true) { [weak self] in
            self?.back()
        }
    }
}
