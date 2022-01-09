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
        lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backgroundColor = .clear
            navigationBar.titleLabel.text = L10n.createANewWallet
            return navigationBar
        }()
        
        private let createWalletButton: WLStepButton = WLStepButton.main(image: .key, imageSize: CGSize(width: 16, height: 15), text: L10n.showYourSecurityKey)
        
        // MARK: - Dependencies
        private let viewModel: CreateWalletViewModelType
        
        // MARK: - Initializer
        init(viewModel: CreateWalletViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
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
            navigationBar.backButton.onTap(self, action: #selector(_back))
            navigationBar.autoPinEdge(toSuperviewSafeArea: .top)
            navigationBar.autoPinEdge(toSuperviewEdge: .leading)
            navigationBar.autoPinEdge(toSuperviewEdge: .trailing)
            
            // content
            let illustration = UIView.ilustrationView(
                image: .explanationPicture,
                title: L10n.secureYourWallet,
                description: L10n.TheFollowingWordsAreSecurityKeyThatYouMustKeepInASafePlaceWrittenInTheCorrectSequence.IfLostNoOneCanRestoreIt.keepItPrivateEvenFromUs)
            
            view.addSubview(illustration)
            illustration.autoPinEdge(.top, to: .bottom, of: navigationBar)
            illustration.autoPinEdge(toSuperviewSafeArea: .left, withInset: 18)
            illustration.autoPinEdge(toSuperviewSafeArea: .right, withInset: 18)
            
            // bottom button
            view.addSubview(createWalletButton)
            createWalletButton.autoPinEdgesToSuperviewSafeArea(with: .init(x: 18, y: 20), excludingEdge: .top)
            createWalletButton.autoPinEdge(.top, to: .bottom, of: illustration, withOffset: 10)
            createWalletButton.onTap(self, action: #selector(navigateToCreateWalletScene))
        }
        
        // MARK: - Navigation
        @objc private func navigateToCreateWalletScene() {
            viewModel.navigateToCreatePhrases()
        }
    
        @objc private func _back() {
            viewModel.back()
        }
    
    }
}
