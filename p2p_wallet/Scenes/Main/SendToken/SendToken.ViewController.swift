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

extension SendToken {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: SendTokenViewModelType
        
        // MARK: - Properties
        private var childNavigationController: UINavigationController!
        
        // MARK: - Initializer
        init(
            walletPubkey: String?,
            destinationAddress: String?
        ) {
            super.init()
            viewModel.set(walletPubkey: walletPubkey, destinationAddress: destinationAddress)
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
                    showAfterConfirmation: showAfterConfirmation,
                    preSelectedNetwork: preSelectedNetwork
                )
                let vc = ChooseRecipientAndNetwork.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case .confirmation:
                let vc = ConfirmViewController()
                childNavigationController.pushViewController(vc, animated: true)
            case .processTransaction(let request, let transactionType):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
                vc.delegate = self
                present(vc, animated: true, completion: nil)
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
