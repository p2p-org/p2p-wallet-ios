//
//  CreateWallet.TermsAndConditionsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/12/2020.
//

import Foundation
import Down

extension CreateWallet {
    class TermsAndConditionsVC: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: CreateWalletViewModelType
        
        // MARK: - Subviews
        private lazy var tabBar = TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
        private lazy var declineButton = UIButton(label: L10n.decline, labelFont: .systemFont(ofSize: 17), textColor: .alert)
            .onTap(self, action: #selector(declineTermsAndConditions))
        
        private lazy var acceptButton = UIButton(label: L10n.accept, labelFont: .boldSystemFont(ofSize: 17), textColor: .h5887ff)
            .onTap(self, action: #selector(acceptTermsAndConditions))
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            
            // markdown
            let filepath = Bundle.main.path(forResource: "Terms_of_service", ofType: "txt")!
            let contents = try! String(contentsOfFile: filepath)
            let downView = try! DownView(frame: self.view.bounds, markdownString: contents)
            
            // stack view
            let stackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
                UILabel(text: L10n.termsAndConditions, textSize: 21, weight: .medium)
                    .padding(.init(x: 20, y: 0))
                UIView.defaultSeparator()
                BEStackViewSpacing(0)
                downView
            }
            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20), excludingEdge: .bottom)
            
            // tabBar
            view.addSubview(tabBar)
            tabBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            tabBar.autoPinEdge(.top, to: .bottom, of: stackView)
            tabBar.stackView.addArrangedSubviews([declineButton, acceptButton])
        }
        
        @objc func acceptTermsAndConditions() {
            viewModel.acceptTermsAndCondition()
        }
        
        @objc func declineTermsAndConditions() {
            viewModel.declineTermsAndCondition()
        }
    }
}
