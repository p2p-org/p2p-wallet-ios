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
    func makeMainVC() -> MainVC
    func makeLocalAuthVC() -> LocalAuthVC
}

class MainViewController: BaseVC {
    
    // MARK: - Properties
    let viewModel: MainViewModel
    let scenesFactory: _MainScenesFactory
    var shouldAuthenticate = true
    
    // MARK: - Initializer
    init(viewModel: MainViewModel, scenesFactory: _MainScenesFactory)
    {
        self.viewModel = viewModel
        self.scenesFactory = scenesFactory
        super.init()
    }
    
    // MARK: - Methods
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldAuthenticate {
            shouldAuthenticate = false
            viewModel.authenticationSubject.onNext(())
        }
    }
    
    override func setUp() {
        super.setUp()
        add(child: scenesFactory.makeMainVC())
    }
    
    override func bind() {
        super.bind()
        viewModel.authenticationSubject
            .subscribe(onNext: {self.authenticate()})
            .disposed(by: disposeBag)
    }
    
    private func authenticate() {
        let localAuthVC = scenesFactory.makeLocalAuthVC()
        localAuthVC.completion = {[weak self] didSuccess in
            self?.viewModel.isAuthenticating = false
            self?.viewModel.lastAuthenticationTimestamp = Date().timeIntervalSince1970
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
        present(localAuthVC, animated: true, completion: nil)
        viewModel.isAuthenticating = true
    }
}
