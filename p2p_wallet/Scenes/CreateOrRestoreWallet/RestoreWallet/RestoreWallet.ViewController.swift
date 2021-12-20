//
//  RestoreWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit
import BEPureLayout
import Resolver

extension RestoreWallet {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: RestoreWalletViewModelType

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
            navigationBar.titleLabel.text = L10n.iVeAlreadyHadAWallet.uppercaseFirst
            
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
                .drive(with: self) { $0.navigate(to: $1) }
                .disposed(by: disposeBag)
            
            viewModel.isLoadingDriver
                .drive(onNext: {
                    $0 ? UIApplication.shared.showIndetermineHud(): UIApplication.shared.hideHud()
                })
                .disposed(by: disposeBag)
            
            viewModel.errorSignal
                .emit(with: self) { $0.showAlert(title: L10n.error, message: $1) }
                .disposed(by: disposeBag)
            
            viewModel.isRestorableUsingIcloud.map({ !$0 }).drive(iCloudRestoreButton.rx.isHidden)
                .disposed(by: disposeBag)
        }

        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }

        // MARK: - Navigation
        private func navigate(to scene: RestoreWallet.NavigatableScene?) {
            guard let scene = scene else { return }
            
            switch scene {
            case .enterPhrases:
                let vc = EnterSeed.ViewController(viewModel: Resolver.resolve())
                navigationController?.pushViewController(vc, animated: true)
            case .restoreFromICloud:
                let vc = RestoreICloud.ViewController()
                navigationController?.pushViewController(vc, animated: true)
            case .derivableAccounts(let phrases):
                let viewModel = DerivableAccounts.ViewModel(phrases: phrases)
                let vc = DerivableAccounts.ViewController(viewModel: viewModel)
                navigationController?.pushViewController(vc, animated: true)
            case .reserveName(let owner):
                let viewModel = ReserveName.ViewModel(
                    kind: .reserveCreateWalletPart,
                    owner: owner,
                    nameService: Resolver.resolve(),
                    reserveNameHandler: viewModel
                )
                let viewController = ReserveName.ViewController(viewModel: viewModel)
                navigationController?.pushViewController(viewController, animated: true)
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
