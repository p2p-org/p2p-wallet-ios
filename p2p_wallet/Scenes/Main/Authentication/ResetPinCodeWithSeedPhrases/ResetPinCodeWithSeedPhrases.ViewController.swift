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
        var childNavigationController: UINavigationController!
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
            childNavigationController = .init()
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
                let createPincodeVC = WLCreatePincodeVC(
                    createPincodeTitle: L10n.newPINCode,
                    confirmPincodeTitle: L10n.confirmPINCode
                )
                createPincodeVC.onSuccess = {[weak self] pincode in
                    self?.viewModel.savePincode(String(pincode))
                    self?.dismiss(animated: true) { [weak self] in
                        self?.completion?()
                    }
                }
                createPincodeVC.onCancel = {[weak createPincodeVC] in
                    createPincodeVC?.dismiss(animated: true, completion: nil)
                }
                childNavigationController.pushViewController(createPincodeVC, animated: true)
            }
        }
    }

}
