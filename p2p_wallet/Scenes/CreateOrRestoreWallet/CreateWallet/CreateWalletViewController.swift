//
//  CreateWalletViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

protocol CreateWalletScenesFactory {
    func makeTermsAndConditionsVC() -> TermsAndConditionsVC
    func makeCreatePhrasesVC() -> CreatePhrasesVC
}

class CreateWalletViewController: WLIndicatorModalVC {
    // MARK: - Properties
    let viewModel: CreateWalletViewModel
    let scenesFactory: CreateWalletScenesFactory
    var childNavigationController: BENavigationController!
    
    // MARK: - Initializer
    init(viewModel: CreateWalletViewModel, scenesFactory: CreateWalletScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        // kickoff Terms and Conditions
        childNavigationController = BENavigationController(rootViewController: scenesFactory.makeTermsAndConditionsVC())
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
            let vc = scenesFactory.makeCreatePhrasesVC()
            childNavigationController.pushViewController(vc, animated: true)
        case .dismiss:
            dismiss(animated: true, completion: nil)
        }
    }
}
