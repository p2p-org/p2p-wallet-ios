//
//  TermsAndConditionsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/12/2020.
//

import Foundation

class TermsAndConditionsVC: WLModalVC {
    override var padding: UIEdgeInsets {.init(x: 0, y: 20)}
    
    lazy var tabBar = TabBarVC.TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
    lazy var declineButton = UIButton(label: L10n.decline, labelFont: .systemFont(ofSize: 17), textColor: .red)
        .onTap(self, action: #selector(back))
    lazy var acceptButton = UIButton(label: L10n.accept, labelFont: .boldSystemFont(ofSize: 17), textColor: .blue)
        .onTap(self, action: #selector(buttonAcceptDidTouch))
    var completion: (() -> Void)?
    
    override func setUp() {
        super.setUp()
        stackView.spacing = 20
        
        let scrollView: ContentHuggingScrollView = {
            let scrollView = ContentHuggingScrollView(scrollableAxis: .vertical)
            // TODO: - Change later
            let label = UILabel(text: "Physiological respiration involves the mechanisms that ensure that the composition of the functional residual capacity is kept constant, and equilibrates with the gases dissolved in the pulmonary capillary blood, and thus throughout the body. Thus, in precise usage, the words breathing and ventilation are hyponyms, not synonyms, of respiration; but this prescription is not consistently followed, even by most health care providers, because the term respiratory rate (RR) is a well-established term in health care, even though it would need to be consistently replaced with ventilation rate if the precise usage were to be followed. (RR) is a well-established term in health care, even though it would need to be consistently replaced with ventilation rate if the precise usage were to be followed.", textSize: 15, numberOfLines: 0)
            scrollView.contentView.addSubview(label)
            label.autoPinEdgesToSuperviewEdges()
            return scrollView
        }()
        
        stackView.addArrangedSubviews([
            UILabel(text: L10n.termsAndConditions, textSize: 21, weight: .medium).padding(.init(x: 20, y: 0)),
            UIView.separator(height: 1, color: .separator),
            scrollView.padding(.init(x: 20, y: 0))
        ])
        
        view.addSubview(tabBar)
        tabBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        
        tabBar.stackView.addArrangedSubviews([declineButton, acceptButton])
    }
    
    @objc func buttonAcceptDidTouch() {
        dismiss(animated: true, completion: completion)
    }
}
