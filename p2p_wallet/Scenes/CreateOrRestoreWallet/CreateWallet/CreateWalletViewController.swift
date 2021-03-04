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
    func makeCreateSecurityKeysViewController() -> CreateSecurityKeysViewController
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
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.kickOff()
    }
    
    override func setUp() {
        super.setUp()
        // kickoff
        childNavigationController = BENavigationController()
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
        case .termsAndConditions:
            let vc = scenesFactory.makeTermsAndConditionsVC()
            childNavigationController.pushViewController(vc, animated: true)
        case .createPhrases:
            let vc = scenesFactory.makeCreateSecurityKeysViewController()
            childNavigationController.pushViewController(vc, animated: true)
        case .dismiss:
            dismiss(animated: true, completion: nil)
        }
    }
}
