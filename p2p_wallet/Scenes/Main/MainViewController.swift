//
//  MainViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Foundation
import UIKit
import Action

protocol _MainScenesFactory {
    func makeHomeViewController() -> HomeViewController
    func makeLocalAuthVC() -> LocalAuthVC
    func makeResetPinCodeWithSeedPhrasesViewController() -> ResetPinCodeWithSeedPhrasesViewController
}

class MainViewController: BaseVC {
    // MARK: - Properties
    private let scenesFactory: _MainScenesFactory
    private let viewModel: MainViewModel
    private var localAuthVC: LocalAuthVC?
    private var resetPinCodeWithASeedPhrasesVC: ResetPinCodeWithSeedPhrasesViewController?
    private let authenticateWhenAppears: Bool
    
    // MARK: - Subviews
    lazy var blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        return blurEffectView
    }()
    
    // MARK: - Initializer
    init(viewModel: MainViewModel, scenesFactory: _MainScenesFactory, authenticateWhenAppears: Bool)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        self.authenticateWhenAppears = authenticateWhenAppears
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if authenticateWhenAppears {
            viewModel.input.authenticationStatus.accept(.login())
        }
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        let nc = BENavigationController(rootViewController: scenesFactory.makeHomeViewController())
        add(child: nc)
        view.addSubview(blurEffectView)
        blurEffectView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        // authentication status
        viewModel.output.currentAuthenticationStatus
            .drive(onNext: {[weak self] in self?.handleAuthenticationStatus($0)})
            .disposed(by: disposeBag)
        
        // reset pin code with a seed phrases
        viewModel.output.isRessetingPasscodeWithSeedPhrases
            .drive(onNext: {[weak self] in self?.showResetPincodeWithASeedPhrasesVC($0)})
            .disposed(by: disposeBag)
        
        // blurEffectView
        viewModel.output.currentAuthenticationStatus
            .map {$0 == nil}
            .drive(blurEffectView.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func handleAuthenticationStatus(_ status: AuthenticationPresentationStyle?) {
        // dismiss
        guard let authStyle = status else {
            localAuthVC?.dismiss(animated: true) { [weak self] in
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authStyle.completion?()
                }
            } else {
                self?.lock(authStyle: authStyle)
            }
        }
        
        // cancelledCompletion
        if !authStyle.isRequired {
            // disable swipe down
            localAuthVC?.isModalInPresentation = true
            
            // handle cancelled by tapping <x>
            localAuthVC?.cancelledCompletion = {[weak self] in
                self?.viewModel.input.authenticationStatus.accept(nil)
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
    
    private func showResetPincodeWithASeedPhrasesVC(_ isShowing: Bool) {
        if isShowing {
            resetPinCodeWithASeedPhrasesVC = scenesFactory.makeResetPinCodeWithSeedPhrasesViewController()
            resetPinCodeWithASeedPhrasesVC!.completion = {[weak self] in
                self?.viewModel.handleResetPasscodeWithASeedPhrase()
                self?.localAuthVC?.completion?(true)
            }
            localAuthVC?.present(resetPinCodeWithASeedPhrasesVC!, animated: true, completion: nil)
        } else {
            resetPinCodeWithASeedPhrasesVC?.back()
            resetPinCodeWithASeedPhrasesVC = nil
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

private func secondsToMinutesSeconds (seconds: Int) -> (Int, Int) {
    return ((seconds % 3600) / 60, (seconds % 3600) % 60)
}
