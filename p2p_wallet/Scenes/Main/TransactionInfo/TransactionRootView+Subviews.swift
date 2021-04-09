//
//  TransactionRootView+Subviews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/04/2021.
//

import Foundation

extension TransactionInfoRootView {
    class TransactionInfoSection<TitleView: UIView, ContentView: UIView>: BEView {
        lazy var stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [titleView, contentView])
        
        let titleView: TitleView
        let contentView: ContentView
        
        init(titleView: TitleView, contentView: ContentView) {
            self.titleView = titleView
            self.contentView = contentView
            super.init(frame: .zero)
            configureForAutoLayout()
        }
        
        override func commonInit() {
            super.commonInit()
            let separator = UIView.separator(height: 1, color: .separator)
            addSubview(separator)
            separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: .defaultPadding))
        }
    }
}
