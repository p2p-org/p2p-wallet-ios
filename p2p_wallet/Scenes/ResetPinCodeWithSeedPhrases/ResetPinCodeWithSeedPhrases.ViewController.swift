//
//  ResetPinCodeWithSeedPhrases.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Foundation
import UIKit

extension ResetPinCodeWithSeedPhrases {
    class ViewController: WLIndicatorModalVC {
        // MARK: - Dependencies
        @Injected private var viewModel: ResetPinCodeWithSeedPhrasesViewModelType
        
        // MARK: - Properties
        var childNavigationController: BENavigationController!
        var completion: (() -> Void)?
        
        // MARK: - ChildVC
        lazy var enterPhrasesVC: EnterPhrasesVC = {
            let vc = EnterPhrasesVC()
            vc.completion = {[weak self] phrases in
                self?.viewModel.handlePhrases(phrases)
            }
            vc.dismissAfterCompletion = false
            return vc
        }()
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            childNavigationController = BENavigationController()
            add(child: childNavigationController, to: containerView)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.errorDriver
                .drive(enterPhrasesVC.error)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: ResetPinCodeWithSeedPhrases.NavigatableScene) {
            switch scene {
            case .enterSeedPhrases:
                childNavigationController.pushViewController(enterPhrasesVC, animated: true)
            case .createNewPasscode:
                let vc = CreatePassCodeVC()
                vc.disableDismissAfterCompletion = true
                vc.completion = {[weak self] completed in
                    if completed {
                        guard let pincode = vc.passcode else {
                            return
                        }
                        self?.viewModel.savePincode(pincode)
                        self?.dismiss(animated: true, completion: { [weak self] in
                            self?.completion?()
                        })
                        return
                    }
                }
                childNavigationController.pushViewController(vc, animated: true)
            }
        }
    }

}
