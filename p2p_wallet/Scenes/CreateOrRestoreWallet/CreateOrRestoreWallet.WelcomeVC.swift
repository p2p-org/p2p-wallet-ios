//
//  CreateOrRestoreWallet.WelcomeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

// MARK: - For mvp (no carousel)
extension CreateOrRestoreWallet {
    class WelcomeVC: WLIntroVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        lazy var createWalletButton = WLButton.stepButton(type: .blue, label: L10n.createNewWallet.uppercaseFirst)
            .onTap(self, action: #selector(navigateToCreateWalletScene))
        lazy var restoreWalletButton = WLButton.stepButton(type: .sub, label: L10n.iVeAlreadyHadAWallet.uppercaseFirst)
            .onTap(self, action: #selector(navigateToRestoreWalletScene))
        
        @Injected private var viewModel: CreateOrRestoreWalletViewModelType
        
        override func setUp() {
            super.setUp()
            
            titleLabel.text = L10n.p2PWallet
            descriptionLabel.text = L10n.secureNonCustodialBankOfFuture + "\n" + L10n.simpleFinanceForEveryone
            
            buttonsStackView.addArrangedSubview(createWalletButton)
            buttonsStackView.addArrangedSubview(restoreWalletButton)
        }
        
        @objc private func navigateToCreateWalletScene() {
            viewModel.navigateToCreateWalletScene()
        }
        
        @objc private func navigateToRestoreWalletScene() {
            viewModel.navigateToRestoreWalletScene()
        }
    }
}

// MARK: - Old (with carousel)
//extension CreateOrRestoreWallet {
//    class WelcomeVC: BEPagesVC, BEPagesVCDelegate {
//        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
//            .hidden
//        }
//
//        // MARK: - Dependencies
//        @Injected private var viewModel: CreateOrRestoreWalletViewModelType
//        @Injected private var analyticsManager: AnalyticsManagerType
//
//        // MARK: - Methods
//        override func viewDidLoad() {
//            super.viewDidLoad()
//            if Defaults.isIntroductionViewed {
//                moveToPage(viewControllers.count - 1)
//                pageControl.isHidden = true
//            }
//            analyticsManager.log(event: .firstInOpen)
//        }
//
//        override func setUp() {
//            super.setUp()
//            viewControllers = [
//                FirstVC(),
//                FirstVC(),
//                FirstVC(),
//                SecondVC()
//            ]
//            currentPageIndicatorTintColor = .white
//            pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
//
//            self.delegate = self
//        }
//
//        func bePagesVC(_ pagesVC: BEPagesVC, currentPageDidChangeTo currentPage: Int) {
//            pageControl.isHidden = false
//            if currentPage == viewControllers.count - 1 {
//                pageControl.isHidden = true
//            }
//            Defaults.isIntroductionViewed = true
//        }
//
//        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//            .portrait
//        }
//
//        override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
//            .portrait
//        }
//    }
//}
//
//extension CreateOrRestoreWallet.WelcomeVC {
//    class SlideVC: WLIntroVC {
//        lazy var createWalletButton = WLButton.stepButton(type: .blue, label: L10n.createNewWallet.uppercaseFirst)
//            .onTap(self, action: #selector(navigateToCreateWalletScene))
//        lazy var restoreWalletButton = WLButton.stepButton(type: .sub, label: L10n.iVeAlreadyHadAWallet.uppercaseFirst)
//            .onTap(self, action: #selector(navigateToRestoreWalletScene))
//
//        @Injected private var viewModel: CreateOrRestoreWalletViewModelType
//
//        override func setUp() {
//            super.setUp()
//
//            buttonsStackView.addArrangedSubview(createWalletButton)
//            buttonsStackView.addArrangedSubview(restoreWalletButton)
//        }
//
//        @objc private func navigateToCreateWalletScene() {
//            viewModel.navigateToCreateWalletScene()
//        }
//
//        @objc private func navigateToRestoreWalletScene() {
//            viewModel.navigateToRestoreWalletScene()
//        }
//    }
//
//    class FirstVC: SlideVC {
//        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
//            .embeded
//        }
//
//        override func setUp() {
//            super.setUp()
//            titleLabel.text = L10n.p2PWallet
//            descriptionLabel.text = L10n.secureNonCustodialBankOfFuture + "\n" + L10n.simpleFinanceForEveryone
//            buttonsStackView.alpha = 0
//        }
//    }
//
//    class SecondVC: SlideVC {
//        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
//            .embeded
//        }
//
//        override func setUp() {
//            super.setUp()
//            titleLabel.text = L10n.p2PWallet
//            descriptionLabel.text = L10n.secureNonCustodialBankOfFuture + "\n" + L10n.simpleFinanceForEveryone
//        }
//    }
//}
