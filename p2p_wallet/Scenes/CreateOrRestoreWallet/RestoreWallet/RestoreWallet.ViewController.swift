//
//  RestoreWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit
import Resolver

extension RestoreWallet {
    class ViewController: WLIntroVC {
        // MARK: - Dependencies
        @Injected private var viewModel: RestoreWalletViewModelType
        
        // MARK: - Subviews
        lazy var iCloudRestoreButton = WLButton.stepButton(enabledColor: .textWhite, textColor: .textBlack, label: " " + L10n.restoreUsingICloud)
            .onTap(self, action: #selector(restoreFromICloud))
        lazy var restoreManuallyButton = WLButton.stepButton(type: .sub, label: L10n.restoreManually)
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
            
            viewModel.errorSignal
                .emit(onNext: {[weak self] message in
                    self?.showAlert(title: L10n.error, message: message)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: RestoreWallet.NavigatableScene?) {
            switch scene {
            case .enterPhrases:
                let wrappedVC = RecoveryEnterSeedsViewController()
                wrappedVC.completion = {[weak self] phrases in
                    self?.viewModel.handlePhrases(phrases)
                }
                let vc = WLModalWrapperVC(wrapped: wrappedVC)
                present(vc, animated: true, completion: nil)
            case .derivableAccounts(let phrases):
                let viewModel = DerivableAccountsViewModel(
                    phrases: phrases,
                    pricesFetcher: CryptoComparePricesFetcher()
                )
                let wrappedVC = DerivableAccountsVC(viewModel: viewModel)

                let vc = WLModalWrapperVC(wrapped: wrappedVC)
                present(vc, animated: true, completion: nil)
            default:
                break
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
