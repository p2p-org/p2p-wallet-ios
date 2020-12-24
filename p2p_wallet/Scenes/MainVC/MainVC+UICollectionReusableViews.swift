//
//  MainFooterView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Action

extension MainVC {
    class FirstSectionHeaderView: SectionHeaderView {
        lazy var avatarImageView = UIImageView(width: 30, height: 30, backgroundColor: .c4c4c4, cornerRadius: 15)
            .onTap(self, action: #selector(avatarImageViewDidTouch))
        lazy var activeStatusView = UIView(width: 8, height: 8, backgroundColor: .red, cornerRadius: 4)
            .onTap(self, action: #selector(avatarImageViewDidTouch))
        var openProfileAction: CocoaAction?
        
        override func commonInit() {
            super.commonInit()
            // remove all arranged subviews
            stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
            
            // add header
            let headerView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill, arrangedSubviews: [
                avatarImageView,
                .spacer
            ])
            
            headerView.addSubview(activeStatusView)
            activeStatusView.autoPinEdge(.top, to: .top, of: avatarImageView)
            activeStatusView.autoPinEdge(.trailing, to: .trailing, of: avatarImageView)
            
            stackView.addArrangedSubview(headerView.padding(.init(x: 20, y: 0)))
        }
        
        @objc func avatarImageViewDidTouch() {
            openProfileAction?.execute()
        }
    }
    
    class FirstSectionFooterView: SectionFooterView {
        var showProductsAction: CocoaAction?
        
        lazy var button: UIView = {
            let view = UIView(backgroundColor: UIColor.white.withAlphaComponent(0.1), cornerRadius: 12)
            view.row([
                UILabel(text: L10n.myBalances, textSize: 17, weight: .medium, textColor: .white),
                UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .textSecondary)
            ], padding: .init(x: 20, y: 16))
            return view
                .onTap(self, action: #selector(buttonDidTouch))
        }()
        
        override func commonInit() {
            super.commonInit()
            stackView.alignment = .fill
            stackView.addArrangedSubview(button.padding(.init(x: .defaultPadding, y: 30)))
        }
        
        @objc func buttonDidTouch() {
            showProductsAction?.execute()
        }
    }
    
    class FirstSectionBackgroundView: SectionBackgroundView {
        override func commonInit() {
            super.commonInit()
            backgroundColor = .h1b1b1b
        }
    }
    
    class SecondSectionBackgroundView: SectionBackgroundView {
        lazy var backgroundView = UIView(backgroundColor: .white)
        
        override func commonInit() {
            super.commonInit()
            backgroundColor = .h1b1b1b
            
            addSubview(backgroundView)
            backgroundView.autoPinEdgesToSuperviewEdges()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            backgroundView.roundCorners([.topLeft, .topRight], radius: 20)
        }
    }
    
    class SecondSectionHeaderView: SectionHeaderView {
        var receiveAction: CocoaAction?
        var sendAction: CocoaAction?
        var exchangeAction: CocoaAction?
        
        override func commonInit() {
            super.commonInit()
            stackView.insertArrangedSubviews([
                UILabel(text: L10n.payments, textSize: 17, weight: .semibold)
                    .padding(.init(x: 20, y: 0)),
                UIView.row([
                    .spacer,
//                    createButton(image: .walletAdd, title: L10n.buy),
                    createButton(image: .walletReceive, title: L10n.receive)
                        .onTap(self, action: #selector(buttonReceiveDidTouch)),
                    createButton(image: .walletSend, title: L10n.send)
                        .onTap(self, action: #selector(buttonSendDidTouch)),
                    createButton(image: .walletSwap, title: L10n.exchange)
                        .onTap(self, action: #selector(buttonExchangeDidTouch)),
                    .spacer
                ])
                    .padding(.init(x: 20, y: 0))
            ], at: 0, withCustomSpacings: [20, 30])
        }
        
        private func createButton(image: UIImage, title: String) -> UIStackView {
            let button = UIButton(width: 56, height: 56, backgroundColor: .f4f4f4, cornerRadius: 12, label: title, contentInsets: .init(all: 16))
            button.setImage(image, for: .normal)
            button.isUserInteractionEnabled = false
            button.tintColor = .textBlack
            return UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill, arrangedSubviews: [
                button,
                UILabel(text: title, textSize: 12)
            ])
        }
        
        @objc func buttonReceiveDidTouch() {
            receiveAction?.execute()
        }
        
        @objc func buttonSendDidTouch() {
            sendAction?.execute()
        }
        
        @objc func buttonExchangeDidTouch() {
            exchangeAction?.execute()
        }
    }
}
