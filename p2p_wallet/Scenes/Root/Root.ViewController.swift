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
        
        // MARK: - Dependencies
        @Injected private var viewModel: RootViewModelType
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            viewModel.reload()
        }
        
        override func bind() {
            super.bind()
            // navigation scene
            viewModel.navigationSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            // loadingView
            viewModel.isLoadingDriver
                .drive(onNext: { [weak self] isLoading in
                    isLoading ? self?.showIndetermineHud(): self?.hideHud()
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .createOrRestoreWallet:
                let vc = CreateOrRestoreWallet.ViewController()
                let nc = UINavigationController(rootViewController: vc)
                transition(to: nc)
            case .onboarding:
                let vc = Onboarding.ViewController()
                transition(to: vc)
            case .onboardingDone(let isRestoration, let name):
                let vc = WelcomeViewController(isReturned: isRestoration, name: name)
                transition(to: vc)
            case .main(let showAuthenticationWhenAppears):
                // MainViewController
                let container = MainContainer()
                let vc = container.makeMainViewController(authenticateWhenAppears: showAuthenticationWhenAppears)
                transition(to: vc)
            default:
                break
            }
        }
    }
}
