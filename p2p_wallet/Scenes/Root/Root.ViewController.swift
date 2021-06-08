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
        override var preferredStatusBarStyle: UIStatusBarStyle {
            isLightStatusBarStyle ? .lightContent: .darkContent
        }
        
        // MARK: - Properties
        private let viewModel: ViewModel
        private let scenesFactory: RootViewControllerScenesFactory
        
        private var isLightStatusBarStyle = false
        private var isBoardingCompleted = true
        private var localAuthVC: LocalAuthVC?
        
        // MARK: - Subviews
        lazy var blurEffectView: UIVisualEffectView = {
            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            return blurEffectView
        }()
        
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
            view.addSubview(blurEffectView)
            blurEffectView.autoPinEdgesToSuperviewEdges()
        }
        
        override func bind() {
            super.bind()
            // navigation scene
            viewModel.output.navigationScene
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            // authentication status
            viewModel.output.currentAuthenticationStatus
                .drive(onNext: {[weak self] in self?.handleAuthenticationStatus($0)})
                .disposed(by: disposeBag)
            
            // blurEffectView
            viewModel.output.currentAuthenticationStatus
                .map {$0 == nil}
                .drive(blurEffectView.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            
            case .createOrRestoreWallet:
                isLightStatusBarStyle = true
                setNeedsStatusBarAppearanceUpdate()
                
                let vc = scenesFactory.makeCreateOrRestoreWalletViewController()
                let nc = BENavigationController(rootViewController: vc)
                isBoardingCompleted = false
                transitionAndMoveBlurViewToFront(to: nc)
                
            case .onboarding:
                isLightStatusBarStyle = true
                setNeedsStatusBarAppearanceUpdate()
                
                let vc = scenesFactory.makeOnboardingViewController()
                isBoardingCompleted = false
                transitionAndMoveBlurViewToFront(to: vc)
                
            case .onboardingDone(let isRestoration):
                isLightStatusBarStyle = true
                setNeedsStatusBarAppearanceUpdate()
                
                let vc: UIViewController = isRestoration ? scenesFactory.makeWelcomeBackVC(): scenesFactory.makeWellDoneVC()
                isBoardingCompleted = false
                transitionAndMoveBlurViewToFront(to: vc)
                
            case .main:
                isLightStatusBarStyle = false
                setNeedsStatusBarAppearanceUpdate()
                
                let vc = scenesFactory.makeMainViewController()
                isBoardingCompleted = true
                transitionAndMoveBlurViewToFront(to: vc)
                
            case .resetPincodeWithASeedPhrase:
                let vc = scenesFactory.makeResetPinCodeWithSeedPhrasesViewController()
                vc.completion = {[weak self] in
//                    self?.viewModel.didResetPinCodeWithSeedPhrases = true
                    self?.localAuthVC?.completion?(true)
                }
                localAuthVC?.present(vc, animated: true, completion: nil)
                
            default:
                break
            }
        }
        
        private func handleAuthenticationStatus(_ status: AuthenticationPresentationStyle?) {
            // dismiss
            guard let authStyle = status else {
                localAuthVC?.dismiss(animated: true) { [weak self] in
                    status?.completion?()
                    self?.localAuthVC = nil
                }
                return
            }
            
            // clean
            localAuthVC?.dismiss(animated: false, completion: nil)
            localAuthVC = scenesFactory.makeLocalAuthVC()
            localAuthVC?.embededPinVC.promptTitle = authStyle.title
            localAuthVC?.isIgnorable = !authStyle.isRequired
            localAuthVC?.useBiometry = authStyle.useBiometry
            
            if authStyle.isFullScreen {
                localAuthVC?.modalPresentationStyle = .fullScreen
            }
            localAuthVC?.disableDismissAfterCompletion = true
            
//            if localAuthVC?.isIgnorable == true {
//                viewModel.markAsIsAuthenticating(false)
//            } else {
//                viewModel.markAsIsAuthenticating(true)
//            }
            
            // reset with a seed phrase
            localAuthVC?.resetPincodeWithASeedPhrasesHandler = {[weak self] in
                self?.viewModel.resetPinCodeWithASeedPhrase()
            }
            
            // completion
            localAuthVC?.completion = {[weak self] didSuccess in
                if didSuccess {
                    self?.viewModel.input.authenticationStatus.accept(nil)
                } else {
                    self?.lock(authStyle: authStyle)
                }
            }
        }
        
        // MARK: - Helpers
        private func lock(authStyle: AuthenticationPresentationStyle?) {
            localAuthVC?.isIgnorable = false
            localAuthVC?.isBlocked = true
            localAuthVC?.embededPinVC.clear()
            
            var secondsLeft = 10
            
            // Count down to next
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                
                secondsLeft -= 1
                
                let minutesAndSeconds = secondsToMinutesSeconds(seconds: secondsLeft)
                let minutes = minutesAndSeconds.0
                let seconds = minutesAndSeconds.1
                
                self?.localAuthVC?.embededPinVC.errorTitle = L10n.weVeLockedYourWalletTryAgainIn("\(minutes) \(L10n.minutes) \(seconds) \(L10n.seconds)") + " " + L10n.orResetItWithASeedPhrase
                self?.localAuthVC?.isResetPinCodeWithASeedPhrasesShown = true
                
                if secondsLeft == 0 {
                    self?.localAuthVC?.embededPinVC.errorTitle = nil
                    self?.localAuthVC?.isBlocked = false
                    self?.localAuthVC?.remainingPinEntries = 3
                    self?.localAuthVC?.isResetPinCodeWithASeedPhrasesShown = false
                    timer.invalidate()
                }
            }
        }
        
        private func transitionAndMoveBlurViewToFront(to vc: UIViewController) {
            transition(to: vc) { [weak self] in
                guard let view = self?.blurEffectView else {return}
                self?.view.bringSubviewToFront(view)
            }
        }
    }
}

private func secondsToMinutesSeconds (seconds: Int) -> (Int, Int) {
    return ((seconds % 3600) / 60, (seconds % 3600) % 60)
}
