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
        private var statusBarStyle: UIStatusBarStyle = .default
        override var preferredStatusBarStyle: UIStatusBarStyle {self.statusBarStyle}
        
        // MARK: - Properties
        private let viewModel: ViewModel
        private let scenesFactory: RootViewControllerScenesFactory
        
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
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .createOrRestoreWallet:
                let vc = scenesFactory.makeCreateOrRestoreWalletViewController()
                let nc = BENavigationController(rootViewController: vc)
                transition(to: nc)
                
                changeStatusBarStyle(.lightContent)
                
            case .onboarding:
                let vc = scenesFactory.makeOnboardingViewController()
                transition(to: vc)
                
                changeStatusBarStyle(.lightContent)
                
            case .onboardingDone(let isRestoration):
                let vc: UIViewController = isRestoration ? scenesFactory.makeWelcomeBackVC(): scenesFactory.makeWellDoneVC()
                transition(to: vc)
                
                changeStatusBarStyle(.lightContent)
                
            case .main(let showAuthenticationWhenAppears):
                let vc = scenesFactory.makeMainViewController(authenticateWhenAppears: showAuthenticationWhenAppears)
                transition(to: vc)
                
                changeStatusBarStyle(.default)
                
            default:
                break
            }
        }
        
        private func changeStatusBarStyle(_ style: UIStatusBarStyle) {
            self.statusBarStyle = style
            setNeedsStatusBarAppearanceUpdate()
        }
    }
}
