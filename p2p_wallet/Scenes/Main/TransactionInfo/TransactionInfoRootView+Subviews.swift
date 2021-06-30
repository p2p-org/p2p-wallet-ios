//
//  TransactionInfoRootView+Subviews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/04/2021.
//

import Foundation

extension TransactionInfoRootView {
    class TransactionInfoSection<TitleView: UIView, ContentView: UIView>: BEView {
        lazy var stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [titleView, contentView])
        
        let titleView: TitleView
        let contentView: ContentView
        
        var spacing: CGFloat {
            get {
                stackView.spacing
            }
            set {
                stackView.spacing = newValue
            }
        }
        
        init(titleView: TitleView, contentView: ContentView) {
            self.titleView = titleView
            self.contentView = contentView
            super.init(frame: .zero)
            configureForAutoLayout()
        }
        
        override func commonInit() {
            super.commonInit()
            let separator = UIView.defaultSeparator()
            addSubview(separator)
            separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: .defaultPadding))
        }
    }
    
    // MARK: - Status view
    class TransactionStatusView: BEView {
        lazy var indicatorView = UIView(width: 8, height: 8, backgroundColor: .greenConfirmed, cornerRadius: 2)
        lazy var label = UILabel(text: L10n.completed, textSize: 13, weight: .semibold, textColor: .iconSecondary)
        
        init() {
            super.init(frame: .zero)
            configureForAutoLayout()
        }
        
        override func commonInit() {
            super.commonInit()
            
            backgroundColor = UIColor.f6f6f8.withAlphaComponent(0.5).onDarkMode(.grayPanel)
            layer.cornerRadius = 6
            layer.masksToBounds = true
            
            let stackView = UIStackView(axis: .horizontal, spacing: 6, alignment: .center, distribution: .fill, arrangedSubviews: [
                indicatorView, label
            ])
            
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 16, y: 6))
        }
        
        func setUp(status: SolanaSDK.ParsedTransaction.Status) {
            indicatorView.backgroundColor = status.indicatorColor
            label.text = status.label
        }
    }
}
