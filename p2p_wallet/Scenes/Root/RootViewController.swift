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
    func makeWelcomeBackVC() -> WelcomeBackVC
    func makeResetPinCodeWithSeedPhrasesViewController() -> ResetPinCodeWithSeedPhrasesViewController
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
        
        viewModel.loadingSubject
            .subscribe(onNext: {[weak self] isLoading in
                if isLoading {
                    self?.showIndetermineHud(nil)
                } else {
                    self?.hideHud()
                }
            })
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
        case .onboardingDone(let isRestoration):
            isLightStatusBarStyle = true
            setNeedsStatusBarAppearanceUpdate()
            
            let vc: UIViewController = isRestoration ? scenesFactory.makeWelcomeBackVC(): scenesFactory.makeWellDoneVC()
            isBoardingCompleted = false
            transition(to: vc)
        case .main:
            isLightStatusBarStyle = false
            setNeedsStatusBarAppearanceUpdate()
            
            let vc = scenesFactory.makeMainViewController()
            isBoardingCompleted = true
            transition(to: vc)
        case .resetPincodeWithASeedPhrase:
            let vc = scenesFactory.makeResetPinCodeWithSeedPhrasesViewController()
            vc.completion = {[weak self] in
                self?.viewModel.didResetPinCodeWithSeedPhrases = true
                self?.localAuthVC?.completion?(true)
            }
            localAuthVC?.present(vc, animated: true, completion: nil)
        }
        view.bringSubviewToFront(blurEffectView)
    }
    
    private func authenticate(_ authStyle: AuthenticationPresentationStyle) {
        viewModel.didResetPinCodeWithSeedPhrases = false
        
        // check if view is fully loaded
        if viewIfLoaded?.window == nil || !isBoardingCompleted || (presentedViewController is LocalAuthVC) {return}
        
        // create localAuthVC
        localAuthVC = scenesFactory.makeLocalAuthVC()
        localAuthVC?.embededPinVC.promptTitle = authStyle.title
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
        // reset with a seed phrase
        localAuthVC?.resetPincodeWithASeedPhrasesHandler = {[weak self] in
            self?.viewModel.resetPinCodeWithASeedPhrase()
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
        localAuthVC?.isResetPinCodeWithASeedPhrasesShown = false
        if isLocked {
            // lock screen
            blurEffectView.isHidden = false
            localAuthVC?.isBlocked = true
            localAuthVC?.embededPinVC.clear()
            
            // Count down to next
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let strongSelf = self else {return}
                
                let secondsLeft = strongSelf.viewModel.secondsLeftToNextAuthentication()
                
                let minutesAndSeconds = secondsToMinutesSeconds(seconds: secondsLeft)
                let minutes = minutesAndSeconds.0
                let seconds = minutesAndSeconds.1
                
                self?.localAuthVC?.embededPinVC.errorTitle = L10n.weVeLockedYourWalletTryAgainIn("\(minutes) \(L10n.minutes) \(seconds) \(L10n.seconds)") + " " + L10n.orResetItWithASeedPhrase
                self?.localAuthVC?.isResetPinCodeWithASeedPhrasesShown = true
                
                if strongSelf.viewModel.isSessionExpired {
                    self?.localAuthVC?.embededPinVC.errorTitle = nil
                    self?.localAuthVC?.isBlocked = false
                    self?.localAuthVC?.remainingPinEntries = 3
                    self?.localAuthVC?.isResetPinCodeWithASeedPhrasesShown = false
                    timer.invalidate()
                }
            }
        } else {
            blurEffectView.isHidden = true
            localAuthVC?.dismiss(animated: true) { [weak self] in
                retryAuthStyle.completion?()
                self?.localAuthVC = nil
            }
        }
    }
}

private func secondsToMinutesSeconds (seconds: Int) -> (Int, Int) {
    return ((seconds % 3600) / 60, (seconds % 3600) % 60)
}
