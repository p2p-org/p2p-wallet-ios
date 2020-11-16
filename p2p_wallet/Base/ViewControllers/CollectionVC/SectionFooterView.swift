//
//  SectionFooterView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

class SectionFooterView: UICollectionReusableView {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .center, distribution: .fill)
    lazy var errorView = ErrorView(cornerRadius: 16)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(x: 0, y: 16))
        stackView.addArrangedSubview(errorView)
        errorView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
            .isActive = true
        errorView.isHidden = true
    }
}

class EmptySectionFooterView: SectionFooterView {
    override func commonInit() {
        super.commonInit()
        stackView.removeFromSuperview()
        autoSetDimension(.height, toSize: 0)
    }
}
