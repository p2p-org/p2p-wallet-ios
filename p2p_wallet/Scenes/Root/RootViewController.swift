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
    override var preferredStatusBarStyle: UIStatusBarStyle {
        isLightStatusBarStyle ? .lightContent: .darkContent
    }
    
    var currentVC: UIViewController? {children.last}
    
    // MARK: - Properties
    let viewModel: RootViewModel
    let scenesFactory: RootViewControllerScenesFactory
    
    var isBoardingCompleted = true
    var isLightStatusBarStyle = false
    
    lazy var blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        return blurEffectView
    }()
    
    var localAuthVC: LocalAuthVC?
    
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
        view.addSubview(blurEffectView)
        blurEffectView.autoPinEdgesToSuperviewEdges()
        blurEffectView.isHidden = true
    }
    
    override func bind() {
        super.bind()
        viewModel.navigationSubject
            .subscribe(onNext: {[unowned self] in self.navigate(to: $0)})
            .disposed(by: disposeBag)
        
        viewModel.authenticationSubject
            .subscribe(onNext: {[unowned self] in self.authenticate($0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: RootNavigatableScene) {
        switch scene {
        case .initializing:
            break
        case .createOrRestoreWallet:
            isLightStatusBarStyle = true
            setNeedsStatusBarAppearanceUpdate()
            
            let vc = scenesFactory.makeCreateOrRestoreWalletViewController()
            let nc = BENavigationController(rootViewController: vc)
            isBoardingCompleted = false
            transition(to: nc)
        case .onboarding:
            isLightStatusBarStyle = true
            setNeedsStatusBarAppearanceUpdate()
            
            let vc = scenesFactory.makeOnboardingViewController()
            isBoardingCompleted = false
            transition(to: vc)
        case .onboardingDone:
            isLightStatusBarStyle = true
            setNeedsStatusBarAppearanceUpdate()
            
            let vc = scenesFactory.makeWellDoneVC()
            isBoardingCompleted = false
            transition(to: vc)
        case .main:
            isLightStatusBarStyle = false
            setNeedsStatusBarAppearanceUpdate()
            
            let vc = scenesFactory.makeMainViewController()
            transition(to: vc)
        }
        view.bringSubviewToFront(blurEffectView)
    }
    
    private func authenticate(_ authStyle: AuthenticationPresentationStyle) {
        // check if view is fully loaded
        if viewIfLoaded?.window == nil, !isBoardingCompleted, localAuthVC?.isBeingPresented == true {return}
        
        // create localAuthVC
        localAuthVC = scenesFactory.makeLocalAuthVC()
        localAuthVC?.isIgnorable = !authStyle.isRequired
        localAuthVC?.useBiometry = authStyle.useBiometry
        if authStyle.isFullScreen {
            localAuthVC?.modalPresentationStyle = .fullScreen
        }
        localAuthVC?.disableDismissAfterCompletion = true
        if localAuthVC?.isIgnorable == true {
            viewModel.markAsIsAuthenticating(false)
        } else {
            viewModel.markAsIsAuthenticating(true)
        }
        
        // completion
        localAuthVC?.completion = {[weak self] didSuccess in
            self?.viewModel.markAsIsAuthenticating(false)
            self?.viewModel.lastAuthenticationTimestamp = Int(Date().timeIntervalSince1970)
            self?.lockScreen(!didSuccess, retryAuthStyle: authStyle)
            if !didSuccess {
                self?.localAuthVC?.isIgnorable = false
            }
        }
        
        // present on top
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(localAuthVC!, animated: true, completion: nil)
        }
    }
    
    private func lockScreen(_ isLocked: Bool, retryAuthStyle: AuthenticationPresentationStyle) {
        if isLocked {
            // lock screen
            blurEffectView.isHidden = false
            
            // Count down to next
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let strongSelf = self else {return}
                
                let secondsLeft = strongSelf.viewModel.secondsLeftToNextAuthentication()
                
                let minutesAndSeconds = secondsToMinutesSeconds(seconds: secondsLeft)
                let minutes = minutesAndSeconds.0
                let seconds = minutesAndSeconds.1
                
                self?.localAuthVC?.embededPinVC.errorTitle = L10n.weVeLockedYourWalletTryAgainIn("\(minutes) \(L10n.minutes) \(seconds) \(L10n.seconds)")
                
                self?.localAuthVC?.isBlocked = true
                self?.localAuthVC?.embededPinVC.clear()
                
                if strongSelf.viewModel.isSessionExpired {
                    self?.localAuthVC?.embededPinVC.errorTitle = nil
                    self?.localAuthVC?.isBlocked = false
                    self?.localAuthVC?.remainingPinEntries = 3
                    timer.invalidate()
                }
            }
        } else {
            blurEffectView.isHidden = true
            localAuthVC?.dismiss(animated: true) {
                retryAuthStyle.completion?()
            }
        }
    }
}

private func secondsToMinutesSeconds (seconds: Int) -> (Int, Int) {
    return ((seconds % 3600) / 60, (seconds % 3600) % 60)
}
