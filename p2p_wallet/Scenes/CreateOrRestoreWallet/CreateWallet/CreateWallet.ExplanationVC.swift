//
// Created by Giang Long Tran on 01.11.21.
//

import Foundation
import UIKit

extension CreateWallet {
    class ExplanationVC: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Subviews
        private lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton
                .onTap(self, action: #selector(back))
            navigationBar.titleLabel.text = L10n.createANewWallet
            return navigationBar
        }()
        
        private lazy var createWalletButton: UIView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                UIImageView(width: 16, height: 15, image: .key)
                UILabel(text: L10n.showYourSecurityKey, textSize: 17, weight: .medium, textColor: .white, numberOfLines: 0)
            }
            let button = UIView(height: 56, backgroundColor: .h5887ff, cornerRadius: 12)
            button.addSubview(stackView)
            stackView.autoCenterInSuperview()
            return button.onTap(self, action: #selector(navigateToCreateWalletScene))
        }()
        
        // MARK: - Dependencies
        @Injected private var viewModel: CreateWalletViewModelType
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
    
            // pattern background view
            let patternView = UIImageView(image: .introPatternBg, tintColor: .textSecondary.withAlphaComponent(0.05))
            view.addSubview(patternView)
            patternView.autoPinEdgesToSuperviewEdges()
            
            // navigation bar
            view.addSubview(navigationBar)
            navigationBar.titleLabel.text = L10n.createANewWallet
            navigationBar.autoPinEdge(toSuperviewSafeArea: .top)
            navigationBar.autoPinEdge(toSuperviewEdge: .leading)
            navigationBar.autoPinEdge(toSuperviewEdge: .trailing)
            
            // content
            let vStack = UIStackView(axis: .vertical, alignment: .center, distribution: .fill) {
                UIView.spacer
                UIImageView(width: 375, height: 349.35, image: .explanationPicture)
                    .centeredHorizontallyView
                UILabel(text: L10n.secureYourWallet, textSize: 34, weight: .bold, numberOfLines: 0, textAlignment: .center)
                    .padding(UIEdgeInsets(only: .top, inset: 20))
                UILabel(
                    text: L10n.TheFollowingWordsAreSecurityKeyThatThatYouMustKeepInASafePlaceWrittenInTheCorrectSequence.IfLostNoOneCanRestoreIt.keepItPrivateEvenFromUs,
                    textSize: 17, weight: .medium, numberOfLines: 0, textAlignment: .center)
                    .padding(UIEdgeInsets(only: .top, inset: 10))
                UIView.spacer
            }.padding(UIEdgeInsets(x: 10, y: 0))
            
            view.addSubview(vStack)
            vStack.autoPinEdge(.top, to: .bottom, of: navigationBar)
            vStack.autoPinEdge(toSuperviewSafeArea: .left, withInset: 18)
            vStack.autoPinEdge(toSuperviewSafeArea: .right, withInset: 18)
            
            // bottom button
            view.addSubview(createWalletButton)
            createWalletButton.autoPinEdgesToSuperviewSafeArea(with: .init(x: 18, y: 20), excludingEdge: .top)
            createWalletButton.autoPinEdge(.top, to: .bottom, of: vStack, withOffset: 10)
        }
        
        // MARK: - Navigation
        @objc private func navigateToCreateWalletScene() {
            viewModel.navigateToCreatePhrases()
        }
    }
}
