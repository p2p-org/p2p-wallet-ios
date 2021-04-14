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
    lazy var emptyView = EmptyView(cornerRadius: 16)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    @available(*, unavailable,
    message: "Loading this view from a nib is unsupported in favor of initializer dependency injection."
    )
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        stackView.addArrangedSubview(errorView.padding(UIEdgeInsets(x: 0, y: 16)))
        errorView.wrapper?.widthAnchor.constraint(equalTo: stackView.widthAnchor)
            .isActive = true
        errorView.wrapper?.isHidden = true
        
        stackView.addArrangedSubview(emptyView.padding(UIEdgeInsets(x: 0, y: 16)))
        emptyView.wrapper?.widthAnchor.constraint(equalTo: stackView.widthAnchor)
            .isActive = true
        emptyView.wrapper?.isHidden = true
    }
    
    func setUp<T: Hashable>(state: FetcherState<T>, isListEmpty: Bool) {
        switch state {
        case .loading, .initializing:
            stackView.arrangedSubviews.forEach { ($0.wrapper ?? $0).isHidden = true}
        case .loaded:
            stackView.arrangedSubviews.forEach {($0.wrapper ?? $0).isHidden = false}
            errorView.wrapper?.isHidden = true
            emptyView.wrapper?.isHidden = !isListEmpty
        case .error(let error):
            stackView.arrangedSubviews.forEach {($0.wrapper ?? $0).isHidden = true}
            errorView.wrapper?.isHidden = false
            errorView.setUpWithError(error)
        }
    }
}
