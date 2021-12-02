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
        private let childNavigationController: BENavigationController
        
        // MARK: - Initializer
        init(viewModel: SendTokenViewModelType, scenesFactory: SendTokenScenesFactory) {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            
            // init with ChooseTokenAndAmountVC
            let vm = viewModel.createChooseTokenAndAmountViewModel()
            let vc = ChooseTokenAndAmount.ViewController(viewModel: vm, scenesFactory: scenesFactory)
            self.childNavigationController = BENavigationController(rootViewController: vc)
            
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            add(child: childNavigationController)
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
            case .chooseTokenAndAmount:
                break
            case .chooseRecipientAndNetwork:
                let vm = viewModel.createChooseRecipientAndNetworkViewModel()
                let vc = ChooseRecipientAndNetwork.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case .confirmation:
                let vc = ConfirmViewController(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            case .processTransaction(let request, let transactionType):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
}
