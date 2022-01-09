//
//  CreateOrRestoreWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

extension CreateOrRestoreWallet {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: CreateOrRestoreWalletViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Subviews
        private lazy var createWalletButton = WLStepButton.main(
            image: .walletButtonSmall,
            text: L10n.createNewWallet.uppercaseFirst
        )
            .onTap(self, action: #selector(navigateToCreateWalletScene))
        private lazy var restoreWalletButton = WLStepButton.sub(
            text: L10n.iVeAlreadyHadAWallet.uppercaseFirst
        )
            .onTap(self, action: #selector(navigateToRestoreWalletScene))
        
        // MARK: - Initializer
        init(viewModel: CreateOrRestoreWalletViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            analyticsManager.log(event: .firstInOpen)
            
            // pattern background view
            let patternView = UIView.introPatternView()
            view.addSubview(patternView)
            patternView.autoPinEdgesToSuperviewEdges()
            
            // pagevc's container view
            let containerView = UIView(forAutoLayout: ())
            view.addSubview(containerView)
            containerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            // button stack view
            let buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
                createWalletButton
                    .withContentHuggingPriority(.required, for: .horizontal)
                restoreWalletButton
                    .withContentHuggingPriority(.required, for: .horizontal)
            }
                .withContentHuggingPriority(.required, for: .horizontal)
            
            view.addSubview(buttonStackView)
            buttonStackView.autoPinEdgesToSuperviewSafeArea(with: .init(x: 18, y: 20), excludingEdge: .top)
            buttonStackView.autoPinEdge(.top, to: .bottom, of: containerView)
            
            // set up container view
            add(child: WelcomeVC(), to: containerView)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .createWallet:
                let vc = CreateWallet.ViewController()
                show(vc, sender: nil)
            case .restoreWallet:
                let vc = RestoreWallet.ViewController()
                show(vc, sender: nil)
            }
        }
        
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            .portrait
        }

        override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
            .portrait
        }
        
        @objc private func navigateToCreateWalletScene() {
            viewModel.navigateToCreateWalletScene()
        }

        @objc private func navigateToRestoreWalletScene() {
            viewModel.navigateToRestoreWalletScene()
        }
    }
}
