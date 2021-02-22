//
//  RootViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit
import Action

protocol RootViewControllerScenesFactory {
    func makeCreateOrRestoreWalletViewController() -> CreateOrRestoreWalletViewController
    func makeOnboardingViewController() -> OnboardingViewController
    func makeMainViewController() -> MainViewController
}

class RootViewController: BaseVC {
    var currentVC: UIViewController? {children.last}
    
    // MARK: - Properties
    let viewModel: RootViewModel
    let scenesFactory: RootViewControllerScenesFactory
    
    var isBoardingCompleted = true
    
    // MARK: - Initializer
    init(
        viewModel: RootViewModel,
        scenesFactory: RootViewControllerScenesFactory
    ) {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        viewModel.reload()
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: RootNavigatableScene) {
        switch scene {
        case .initializing:
            break
        case .createOrRestoreWallet:
            let vc = scenesFactory.makeCreateOrRestoreWalletViewController()
            let nc = BENavigationController(rootViewController: vc)
            isBoardingCompleted = false
            transition(to: nc)
        case .onboarding:
            let vc = scenesFactory.makeOnboardingViewController()
            isBoardingCompleted = false
            transition(to: vc)
        case .main:
            let vc = scenesFactory.makeMainViewController()
            vc.shouldAuthenticate = isBoardingCompleted
            transition(to: vc)
        }
    }
}
