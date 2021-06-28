//
//  TermsAndConditionsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/12/2020.
//

import Foundation

class TermsAndConditionsVC: BaseVStackVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    override var padding: UIEdgeInsets {
        .init(top: 20, left: 0, bottom: 20, right: 0)
    }
    
    lazy var tabBar = TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
    lazy var declineButton = UIButton(label: L10n.decline, labelFont: .systemFont(ofSize: 17), textColor: .alert)
        .onTap(createWalletViewModel, action: #selector(CreateWalletViewModel.declineTermsAndCondition))
    
    lazy var acceptButton = UIButton(label: L10n.accept, labelFont: .boldSystemFont(ofSize: 17), textColor: .h5887ff)
        .onTap(createWalletViewModel, action: #selector(CreateWalletViewModel.acceptTermsAndCondition))
    
    let createWalletViewModel: CreateWalletViewModel
    init(createWalletViewModel: CreateWalletViewModel) {
        self.createWalletViewModel = createWalletViewModel
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        // TODO: - Change later
        let text = """
        Physiological respiration involves the mechanisms that ensure that the composition of the functional residual capacity is kept constant, and equilibrates with the gases dissolved in the pulmonary capillary blood, and thus throughout the body.
        Thus, in precise usage, the words breathing and ventilation are hyponyms, not synonyms, of respiration;
            but this prescription is not consistently followed, even by most health care providers, because the term respiratory rate (RR) is a well-established term in health care,
            even though it would need to be consistently replaced with ventilation rate if the precise usage were to be followed.
        (RR) is a well-established term in health care, even though it would need to be consistently replaced with ventilation rate if the precise usage were to be followed.
        """
        let label = UILabel(text: text, numberOfLines: 0)
        
        stackView.spacing = 20
        stackView.addArrangedSubviews([
            UILabel(text: L10n.termsAndConditions, textSize: 21, weight: .medium).padding(.init(x: 20, y: 0)),
            UIView.defaultSeparator(),
            label.padding(.init(x: 20, y: 0))
        ])
        
        view.addSubview(tabBar)
        tabBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        
        tabBar.stackView.addArrangedSubviews([declineButton, acceptButton])
    }
}
