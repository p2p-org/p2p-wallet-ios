//
//  SectionHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/3/20.
//

import Foundation

class SectionHeaderView: UICollectionReusableView {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .center, distribution: .fill)
    
    lazy var headerLabel = UILabel(text: "Wallets", textSize: 17, weight: .bold, numberOfLines: 0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        addSubview(stackView)
        stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
        stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16)
        stackView.autoPinEdge(toSuperviewEdge: .leading)
        stackView.autoPinEdge(toSuperviewEdge: .trailing)
        
        stackView.addArrangedSubview(headerLabel.padding(.init(x: 16, y: 0)))
        headerLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor)
            .isActive = true
    }
    
    func setUp(headerTitle: String, headerFont: UIFont = .systemFont(ofSize: 17, weight: .bold)) {
        headerLabel.text = headerTitle
        headerLabel.font = headerFont
    }
}
