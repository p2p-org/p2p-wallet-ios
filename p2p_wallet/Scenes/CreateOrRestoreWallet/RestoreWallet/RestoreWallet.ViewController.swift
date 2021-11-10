//
//  RestoreWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit
import BEPureLayout

extension RestoreWallet {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: RestoreWalletViewModelType
        
        // MARK: - Subviewcontrollers
        private lazy var childNavigationController: BENavigationController = .init()
        private lazy var childNavigationControllerVCWrapper: WLModalWrapperVC = .init(wrapped: childNavigationController)
        
        // MARK: - Subviews
        private lazy var iCloudRestoreButton = WLStepButton.main(
            image: .appleLogo,
            text: L10n.restoreUsingICloud
        )
            .onTap(self, action: #selector(restoreFromICloud))
        
        private lazy var restoreManuallyButton = WLStepButton.sub(
            text: L10n.restoreManually
        )
            .onTap(self, action: #selector(restoreManually))
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            // pattern background view
            let patternView = UIView.introPatternView()
            view.addSubview(patternView)
            patternView.autoPinEdgesToSuperviewEdges()
            
            // navigation bar
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton.onTap(self, action: #selector(back))
            navigationBar.titleLabel.text = L10n.iVeAlreadyHadAWallet
            
            // content
            let stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
                navigationBar
                UIView.ilustrationView(
                    image: .introImportAWallet,
                    title: L10n.importAWallet,
                    description: L10n.ICloudRestoreIsForReturningUsers.pastingTheSecurityKeyManuallyIsForEveryone
                )
                    .padding(.init(x: 20, y: 0))
                iCloudRestoreButton.padding(.init(x: 20, y: 0))
                restoreManuallyButton.padding(.init(x: 20, y: 0))
            }
            
            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            stackView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 20)
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
