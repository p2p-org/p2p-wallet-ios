//
//  CreateOrRestoreWallet.WelcomeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import UIKit
import BEPureLayout

extension CreateOrRestoreWallet {
    class WelcomeVC: BEPagesVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Dependencies
        @Injected private var viewModel: CreateOrRestoreWalletViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType

        // MARK: - Methods
        override func viewDidLoad() {
            super.viewDidLoad()
            analyticsManager.log(event: .firstInOpen)
        }

        override func setUp() {
            super.setUp()
            viewControllers = [
                FirstVC(),
                SecondVC()
            ]
            currentPageIndicatorTintColor = .h5887ff
            pageIndicatorTintColor = .d1d1d6
        }
        
        override func setUpPageControl() {
            view.addSubview(pageControl)
            pageControl.autoAlignAxis(toSuperviewAxis: .vertical)
            pageControl.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 178)
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            .portrait
        }

        override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
            .portrait
        }
    }
}

private extension CreateOrRestoreWallet.WelcomeVC {
    class SlideVC: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .embeded
        }
        
        @Injected private var viewModel: CreateOrRestoreWalletViewModelType
        
        fileprivate let contentStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
        
        private lazy var createWalletButton: UIView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                UIImageView(width: 24, height: 24, image: .walletButtonSmall)
                UILabel(text: L10n.createNewWallet.uppercaseFirst, textSize: 17, weight: .medium, textColor: .white, numberOfLines: 0)
            }
            let button = UIView(height: 56, backgroundColor: .h5887ff, cornerRadius: 12)
            button.addSubview(stackView)
            stackView.autoCenterInSuperview()
            return button
                .onTap(self, action: #selector(navigateToCreateWalletScene))
        }()
        lazy var restoreWalletButton: UIView = {
            let label = UILabel(text: L10n.iVeAlreadyHadAWallet.uppercaseFirst, textSize: 17, weight: .medium, textColor: .h5887ff, numberOfLines: 0)
            let button = UIView(height: 56)
            button.addSubview(label)
            label.autoCenterInSuperview()
            return button
                .onTap(self, action: #selector(navigateToRestoreWalletScene))
        }()
        
        override func setUp() {
            super.setUp()
            // pattern background view
            let patternView = UIImageView(image: .introPatternBg)
            view.addSubview(patternView)
            patternView.autoPinEdgesToSuperviewEdges()
            
            // content stack view
            view.addSubview(contentStackView)
            contentStackView.autoPinEdge(toSuperviewSafeArea: .top)
            contentStackView.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 20)
            contentStackView.autoPinEdge(toSuperviewSafeArea: .trailing, withInset: 20)
            
            let spacer1 = UIView.spacer
            let spacer2 = UIView.spacer
            contentStackView.addArrangedSubview(spacer1)
            contentStackView.addArrangedSubview(spacer2)
            spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor).isActive = true
            
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
            buttonStackView.autoPinEdge(.top, to: .bottom, of: contentStackView, withOffset: 62)
        }

        @objc private func navigateToCreateWalletScene() {
            viewModel.navigateToCreateWalletScene()
        }

        @objc private func navigateToRestoreWalletScene() {
            viewModel.navigateToRestoreWalletScene()
        }
    }

    class FirstVC: SlideVC {
        override func setUp() {
            super.setUp()
            var index = 1
            contentStackView.insertArrangedSubviews(at: &index) {
                createIconView()
                    .centeredHorizontallyView
                UILabel(text: L10n.p2PWallet, textSize: 34, weight: .bold, textAlignment: .center)
                UILabel(text: L10n.theFutureOfNonCustodialBankingTheEasyWayToBuySellAndHoldCryptos, textSize: 17, weight: .medium, numberOfLines: 0, textAlignment: .center)
            }
        }
        
        private func createIconView() -> UIView {
            let iconView = UIView(forAutoLayout: ())
            let backView = BERoundedCornerShadowView(shadowColor: .black.withAlphaComponent(0.05), radius: 32, offset: .init(width: 0, height: 9), opacity: 1, cornerRadius: 12.5)
            backView.backgroundColor = view.backgroundColor
            backView.autoSetDimension(.width, toSize: 241.16)
            iconView.addSubview(backView)
            backView.autoPinEdge(toSuperviewEdge: .top, withInset: 24.53)
            backView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18.3)
            backView.autoAlignAxis(toSuperviewAxis: .vertical)
            
            let imageView = UIImageView(width: 375, height: 349.35, image: .walletsIcon3d)
            iconView.addSubview(imageView)
            imageView.autoPinEdge(toSuperviewEdge: .top)
            imageView.autoPinEdge(toSuperviewEdge: .bottom)
            imageView.autoAlignAxis(toSuperviewAxis: .vertical)
            
            return iconView
        }
    }

    class SecondVC: SlideVC {
        override func setUp() {
            super.setUp()
            var index = 1
            contentStackView.insertArrangedSubviews(at: &index) {
                UIImageView(width: 196.94, height: 306, image: .p2pCamp)
                    .centeredHorizontallyView
                BEStackViewSpacing(31.34)
                UILabel(text: L10n.welcomeToP2PFamilyCamp, textSize: 34, weight: .bold, numberOfLines: 0, textAlignment: .center)
            }
        }
    }
}
