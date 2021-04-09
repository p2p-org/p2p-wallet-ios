//
//  ScrollableVStackRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/02/2021.
//

import Foundation

class ScrollableVStackRootView: BEView {
    lazy var scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: UIEdgeInsets(top: .defaultPadding, left: .defaultPadding, bottom: 24, right: .defaultPadding))
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    
    override func commonInit() {
        super.commonInit()
        // scroll view for flexible height
        addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        scrollView.autoPinBottomToSuperViewAvoidKeyboard()
        
        // stackView
        scrollView.contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
}
