//
//  RestoreWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

extension RestoreWallet {
    class ViewController: WLIntroVC {
        // MARK: - Dependencies
        @Injected private var viewModel: RestoreWalletViewModelType
        
        // MARK: - Subviewcontrollers
        private lazy var childNavigationController: BENavigationController = .init()
        private lazy var childNavigationControllerVCWrapper: WLModalWrapperVC = .init(wrapped: childNavigationController)
        
        // MARK: - Subviews
        private lazy var iCloudRestoreButton = WLButton.stepButton(enabledColor: .textWhite, textColor: .textBlack, label: " " + L10n.restoreUsingICloud)
            .onTap(self, action: #selector(restoreFromICloud))
        private lazy var restoreManuallyButton = WLButton.stepButton(type: .sub, label: L10n.restoreManually)
            .onTap(self, action: #selector(restoreManually))
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            backButton.isHidden = false
            descriptionLabel.isHidden = false
            titleLabel.text = L10n.p2PWalletRecovery
            descriptionLabel.text = L10n.recoverYourP2PWalletManuallyOrUsingCloudServices
            
            buttonsStackView.addArrangedSubviews([
                iCloudRestoreButton,
                restoreManuallyButton
            ])
        }
        
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.isLoadingDriver
                .drive(onNext: {[weak self] isLoading in
                    isLoading ? self?.childNavigationControllerVCWrapper.showIndetermineHud(): self?.childNavigationControllerVCWrapper.hideHud()
                })
                .disposed(by: disposeBag)
            
            viewModel.errorSignal
                .emit(onNext: {[weak self] message in
                    self?.showAlert(title: L10n.error, message: message)
                })
                .disposed(by: disposeBag)
            
            viewModel.finishedSignal
                .emit(onNext: { [weak self] in
                    self?.childNavigationControllerVCWrapper.dismiss(animated: true, completion: nil)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: RestoreWallet.NavigatableScene?) {
            guard let scene = scene else {return}
            if childNavigationControllerVCWrapper.presentingViewController == nil {
                present(childNavigationControllerVCWrapper, animated: true, completion: nil)
            }
            
            switch scene {
            case .enterPhrases:
                let vc = RecoveryEnterSeedsViewController()
                vc.dismissAfterCompletion = false
                vc.completion = {[weak self] phrases in
                    self?.viewModel.handlePhrases(phrases)
                }
                
                childNavigationController.setViewControllers([vc], animated: false)
            case .restoreFromICloud:
                let vc = RestoreICloud.ViewController()
                childNavigationController.setViewControllers([vc], animated: false)
            case .derivableAccounts(let phrases):
                let viewModel = DerivableAccounts.ViewModel(phrases: phrases)
                let vc = DerivableAccounts.ViewController(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            case .reserveName(let owner):
                let viewModel = ReserveName.ViewModel(owner: owner, handler: viewModel)
                let vc = ReserveNameVC(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            }
        }
        
        // MARK: - Actions
        @objc func restoreFromICloud() {
            viewModel.restoreFromICloud()
        }
        
        @objc func restoreManually() {
            viewModel.restoreManually()
        }
    }
}

private class ReserveNameVC: ReserveName.ViewController {
    override func bind() {
        super.bind()
        viewModel.isPostingDriver
            .drive(onNext: {[weak self] isPosting in
                self?.navigationController?.parent?.isModalInPresentation = isPosting
            })
            .disposed(by: disposeBag)
    }
}
