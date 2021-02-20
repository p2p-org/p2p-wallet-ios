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
    func makeMainViewController() -> UIViewController
    func makeLocalAuthVC() -> LocalAuthVC
}

class RootViewController: BaseVC {
    var currentVC: UIViewController? {children.last}
    
    // MARK: - Properties
    let viewModel: RootViewModel
    let scenesFactory: RootViewControllerScenesFactory
    
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
        
        viewModel.authenticationSubject
            .subscribe(onNext: {self.authenticate()})
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
            transition(to: nc)
        case .onboarding:
            let vc = scenesFactory.makeOnboardingViewController()
            transition(to: vc)
        case .main:
            let vc = scenesFactory.makeMainViewController()
            transition(to: vc)
        }
    }
    
    private func authenticate() {
        let localAuthVC = scenesFactory.makeLocalAuthVC()
        localAuthVC.completion = { [self] didSuccess in
            viewModel.localAuthVCShown = false
            if !didSuccess {
                currentVC?.showErrorView()
                // reset timestamp
                viewModel.rescheduleAuth()
                
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                    currentVC?.errorView?.descriptionLabel.text = L10n.authenticationFailed + "\n" + L10n.retryAfter + " \(Int(10 - Date().timeIntervalSince1970 + viewModel.timestamp) + 1) " + L10n.seconds

                    if Int(Date().timeIntervalSince1970) == Int(viewModel.timestamp + viewModel.timeRequiredForAuthentication) {
                        currentVC?.errorView?.descriptionLabel.text = L10n.tapButtonToRetry
                        currentVC?.errorView?.buttonAction = CocoaAction {
                            authenticate()
                            return .just(())
                        }
                        timer.invalidate()
                    }
                }
            } else {
                currentVC?.removeErrorView()
            }
        }
        localAuthVC.modalPresentationStyle = .fullScreen
        currentVC?.present(localAuthVC, animated: true, completion: nil)
        viewModel.localAuthVCShown = true
    }
}
