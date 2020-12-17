//
//  TermsAndConditionsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/12/2020.
//

import Foundation

class TermsAndConditionsVC: BaseVC {
    lazy var containerView = UIView(backgroundColor: .vcBackground)
    lazy var tabBar = TabBarVC.TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
    lazy var declineButton = UIButton(label: L10n.decline, labelFont: .systemFont(ofSize: 17), textColor: .red)
        .onTap(self, action: #selector(back))
    lazy var acceptButton = UIButton(label: L10n.accept, labelFont: .boldSystemFont(ofSize: 17), textColor: .blue)
        .onTap(self, action: #selector(buttonAcceptDidTouch))
    var completion: (() -> Void)?
    
    // MARK: - Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear
        let topGestureView = UIView(width: 71, height: 5, backgroundColor: .vcBackground, cornerRadius: 2.5)
        view.addSubview(topGestureView)
        topGestureView.autoPinEdge(toSuperviewSafeArea: .top)
        topGestureView.autoAlignAxis(toSuperviewAxis: .vertical)
        
        view.addSubview(containerView)
        containerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        containerView.autoPinEdge(.top, to: .bottom, of: topGestureView, withOffset: 8)
        
        let headerLabel = UILabel(text: L10n.termsAndConditions, textSize: 21, weight: .medium)
        containerView.addSubview(headerLabel)
        headerLabel.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .bottom)
        
        let separator = UIView.separator(height: 1, color: .separator)
        containerView.addSubview(separator)
        separator.autoPinEdge(.top, to: .bottom, of: headerLabel, withOffset: 20)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        
        let scrollView = ContentHuggingScrollView(scrollableAxis: .vertical)
        containerView.addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .top)
        scrollView.autoPinEdge(.top, to: .bottom, of: separator, withOffset: 20)
        
        let label = UILabel.init(text: "Physiological respiration involves the mechanisms that ensure that the composition of the functional residual capacity is kept constant, and equilibrates with the gases dissolved in the pulmonary capillary blood, and thus throughout the body. Thus, in precise usage, the words breathing and ventilation are hyponyms, not synonyms, of respiration; but this prescription is not consistently followed, even by most health care providers, because the term respiratory rate (RR) is a well-established term in health care, even though it would need to be consistently replaced with ventilation rate if the precise usage were to be followed. (RR) is a well-established term in health care, even though it would need to be consistently replaced with ventilation rate if the precise usage were to be followed.", textSize: 15, numberOfLines: 0)
        scrollView.contentView.addSubview(label)
        label.autoPinEdgesToSuperviewEdges()
        
        view.addSubview(tabBar)
        tabBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        
        tabBar.stackView.addArrangedSubviews([declineButton, acceptButton])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.roundCorners([.topLeft, .topRight], radius: 20)
    }
    
    @objc func buttonAcceptDidTouch() {
        dismiss(animated: true, completion: completion)
    }
}
