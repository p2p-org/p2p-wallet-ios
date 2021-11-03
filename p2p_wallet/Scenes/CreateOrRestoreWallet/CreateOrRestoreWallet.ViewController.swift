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
        @Injected private var viewModel: CreateOrRestoreWalletViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Subviews
        private lazy var createWalletButton: UIView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                UIImageView(width: 24.adaptiveHeight, height: 24.adaptiveHeight, image: .walletButtonSmall)
                UILabel(text: L10n.createNewWallet.uppercaseFirst, textSize: 17.adaptiveHeight, weight: .medium, textColor: .white, numberOfLines: 0)
            }
            let button = UIView(height: 56.adaptiveHeight, backgroundColor: .h5887ff, cornerRadius: 12)
            button.addSubview(stackView)
            stackView.autoCenterInSuperview()
            return button
                .onTap(self, action: #selector(navigateToCreateWalletScene))
        }()
        private lazy var restoreWalletButton: UIView = {
            let label = UILabel(text: L10n.iVeAlreadyHadAWallet.uppercaseFirst, textSize: 17.adaptiveHeight, weight: .medium, textColor: .h5887ff, numberOfLines: 0)
            let button = UIView(height: 56.adaptiveHeight)
            button.addSubview(label)
            label.autoCenterInSuperview()
            return button
                .onTap(self, action: #selector(navigateToRestoreWalletScene))
        }()
        
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
                vc.isModalInPresentation = true
                present(vc, animated: true, completion: nil)
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
