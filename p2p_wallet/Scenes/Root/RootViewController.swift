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
    func makeLocalAuthVC() -> LocalAuthVC
    func makeWellDoneVC() -> WellDoneVC
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
            isBoardingCompleted = false
            transition(to: nc)
        case .onboarding:
            let vc = scenesFactory.makeOnboardingViewController()
            isBoardingCompleted = false
            transition(to: vc)
        case .onboardingDone:
            let vc = scenesFactory.makeWellDoneVC()
            isBoardingCompleted = false
            transition(to: vc)
        case .main:
            let vc = scenesFactory.makeMainViewController()
            transition(to: vc)
        }
    }
    
    private func authenticate() {
        if viewIfLoaded?.window == nil, !isBoardingCompleted {return}
        
        let localAuthVC = scenesFactory.makeLocalAuthVC()
        localAuthVC.completion = {[weak self] didSuccess in
            self?.viewModel.isAuthenticating = false
            self?.viewModel.lastAuthenticationTimestamp = Int(Date().timeIntervalSince1970)
            if !didSuccess {
                // show error
                self?.showErrorView()
                
                // Count down to next
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                    guard let strongSelf = self else {return}
                    
                    let secondsLeft = strongSelf.viewModel.secondsLeftToNextAuthentication()
                    
                    strongSelf.errorView?.descriptionLabel.text =
                        L10n.authenticationFailed +
                        "\n" +
                        L10n.retryAfter + " \(secondsLeft) " + L10n.seconds
                    
                    if strongSelf.viewModel.isSessionExpired {
                        strongSelf.errorView?.descriptionLabel.text = L10n.tapButtonToRetry
                        strongSelf.errorView?.buttonAction = CocoaAction {
                            strongSelf.viewModel.authenticationSubject.onNext(())
                            return .just(())
                        }
                        timer.invalidate()
                    }
                }

            } else {
                self?.removeErrorView()
            }
        }
        localAuthVC.modalPresentationStyle = .fullScreen
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(localAuthVC, animated: true, completion: nil)
        }
        
        viewModel.isAuthenticating = true
    }
}
