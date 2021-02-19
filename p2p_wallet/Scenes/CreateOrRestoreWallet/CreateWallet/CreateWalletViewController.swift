//
//  CreateWalletViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

class CreateWalletViewController: WLIndicatorModalVC {
    // MARK: - Properties
    let viewModel: CreateWalletViewModel
    var childNavigationController: BENavigationController!
    
    // MARK: - Initializer
    init(viewModel: CreateWalletViewModel)
    {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        // kickoff Terms and Conditions
        childNavigationController = BENavigationController(rootViewController: TermsAndConditionsVC(createWalletViewModel: viewModel))
        add(child: childNavigationController, to: containerView)
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: CreateWalletNavigatableScene) {
        switch scene {
        case .createPhrases:
            let vc = DependencyContainer.shared.makeCreatePhrasesVC(createWalletViewModel: viewModel)
            childNavigationController.pushViewController(vc, animated: true)
        case .completed:
            let vc = DependencyContainer.shared.makeCreateWalletCompletedVC(createWalletViewModel: viewModel)
            childNavigationController.pushViewController(vc, animated: true)
        case .dismiss:
            dismiss(animated: true, completion: nil)
        }
    }
}
