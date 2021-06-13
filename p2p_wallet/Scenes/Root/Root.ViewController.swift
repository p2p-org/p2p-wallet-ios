//
//  Root.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import UIKit

extension Root {
    class ViewController: BaseVC {
        // MARK: - Properties
        private let viewModel: ViewModel
        private let scenesFactory: RootViewControllerScenesFactory
        private var authenticateWhenAppears = true
        
        // MARK: - Initializer
        init(
            viewModel: ViewModel,
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
            // navigation scene
            viewModel.output.navigationScene
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            // loadingView
            viewModel.output.isLoading
                .drive(onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.showIndetermineHud()
                    } else {
                        self?.hideHud()
                    }
                })
                .disposed(by: disposeBag)
        }
        
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            setNeedsStatusBarAppearanceUpdate()
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .createOrRestoreWallet:
                let vc = scenesFactory.makeCreateOrRestoreWalletViewController()
                let nc = BENavigationController(rootViewController: vc)
                authenticateWhenAppears = false
                transition(to: nc)
                
            case .onboarding:
                let vc = scenesFactory.makeOnboardingViewController()
                authenticateWhenAppears = false
                transition(to: vc)
                
            case .onboardingDone(let isRestoration):
                let vc: UIViewController = isRestoration ? scenesFactory.makeWelcomeBackVC(): scenesFactory.makeWellDoneVC()
                authenticateWhenAppears = false
                transition(to: vc)
                
            case .main:
                let vc = scenesFactory.makeMainViewController(authenticateWhenAppears: authenticateWhenAppears)
                transition(to: vc)
                
            default:
                break
            }
            
            setNeedsStatusBarAppearanceUpdate()
        }
    }
}
