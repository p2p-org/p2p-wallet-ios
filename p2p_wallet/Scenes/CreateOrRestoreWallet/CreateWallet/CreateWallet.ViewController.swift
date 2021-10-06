//
//  CreateWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

extension CreateWallet {
    class ViewController: WLIndicatorModalVC {
        // MARK: - Dependencies
        @Injected private var viewModel: CreateWalletViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        var childNavigationController: BENavigationController!
        
        // MARK: - Methods
        override func viewDidLoad() {
            super.viewDidLoad()
            viewModel.kickOff()
            analyticsManager.log(event: .createWalletOpen)
        }
        
        override func setUp() {
            super.setUp()
            // kickoff
            childNavigationController = BENavigationController()
            add(child: childNavigationController, to: containerView)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: CreateWallet.NavigatableScene?) {
            switch scene {
            case .termsAndConditions:
                let vc = TermsAndConditionsVC()
                childNavigationController.pushViewController(vc, animated: true)
            case .createPhrases:
                let vc = CreateSecurityKeys.ViewController()
                childNavigationController.pushViewController(vc, animated: true)
            case .reserveName(let owner):
                let vm = ReserveName.ViewModel(owner: owner, handler: viewModel)
                let vc = ReserveName.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case .dismiss:
                dismiss(animated: true, completion: nil)
            case .none:
                break
            }
        }
    }
}
