//
//  RootViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit
import Action

class RootViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: RootViewModel
    var currentVC: UIViewController? {children.last}
    
    // MARK: - Initializer
    init(viewModel: RootViewModel)
    {
        self.viewModel = viewModel
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
        var vcToAdd: UIViewController?
        switch scene {
        case .initializing:
            break
        case .createOrRestoreWallet:
            let vc = DependencyContainer.shared.makeCreateOrRestoreWalletViewController()
            vcToAdd = BENavigationController(rootViewController: vc)
        case .onboarding:
            vcToAdd = DependencyContainer.shared.makeOnboardingViewController()
        case .main:
            vcToAdd = DependencyContainer.shared.makeTabBarVC()
        }
        
        if let vc = vcToAdd {
            removeAllChilds()
            add(child: vc)
        }
    }
    
    private func authenticate() {
        let localAuthVC = DependencyContainer.shared.makeLocalAuthVC()
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
