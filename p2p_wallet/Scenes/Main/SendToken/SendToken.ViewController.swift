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
    func makeChooseWalletViewController(
        title: String?,
        customFilter: ((Wallet) -> Bool)?,
        showOtherWallets: Bool,         
        selectedWallet: Wallet?,
        handler: WalletDidSelectHandler
    ) -> ChooseWallet.ViewController
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
        private var childNavigationController: UINavigationController!
        
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
                    showAfterConfirmation: showAfterConfirmation,
                    selectedNetwork: viewModel.getSelectedNetwork()
                )
                let vc = ChooseTokenAndAmount.ViewController(viewModel: vm, scenesFactory: scenesFactory)
                
                if showAfterConfirmation {
                    childNavigationController.pushViewController(vc, animated: true)
                } else {
                    childNavigationController = .init(rootViewController: vc)
                    add(child: childNavigationController)
                }
            case .chooseRecipientAndNetwork(let showAfterConfirmation, let preSelectedNetwork):
                let vm = ChooseRecipientAndNetwork.ViewModel(
                    sendTokenViewModel: viewModel,
                    showAfterConfirmation: showAfterConfirmation,
                    preSelectedNetwork: preSelectedNetwork
                )
                let vc = ChooseRecipientAndNetwork.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case .confirmation:
                let vc = ConfirmViewController(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            case .processTransaction(let request, let transactionType):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
                vc.delegate = self
                present(vc, interactiveDismissalType: .none, completion: nil)
            case .chooseNetwork:
                let vc = SelectNetwork.ViewController(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
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
