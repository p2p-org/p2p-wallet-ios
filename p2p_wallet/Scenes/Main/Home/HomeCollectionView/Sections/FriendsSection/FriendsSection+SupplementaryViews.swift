//
//  FriendsSection+SupplementaryViews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import Action

extension FriendsSection {
    class FriendsSectionBackgroundView: SectionBackgroundView {
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
    
    class HeaderView: SectionHeaderView {
        var buyAction: CocoaAction?
        var receiveAction: CocoaAction?
        var sendAction: CocoaAction?
        var swapAction: CocoaAction?
        
        override func commonInit() {
            super.commonInit()
            var index = 0
            stackView.insertArrangedSubviewsWithCustomSpacing([
                UILabel(text: L10n.payments, textSize: 17, weight: .semibold)
                    .padding(.init(x: 20, y: 0)),
                BEStackViewSpacing(20),
                UIView.row([
                    .spacer,
                    createButton(image: .walletAdd, title: L10n.buy)
                        .onTap(self, action: #selector(buttonAddDidTouch)),
                    createButton(image: .walletReceive, title: L10n.receive)
                        .onTap(self, action: #selector(buttonReceiveDidTouch)),
                    createButton(image: .walletSend, title: L10n.send)
                        .onTap(self, action: #selector(buttonSendDidTouch)),
                    createButton(image: .walletSwap, title: L10n.swap)
                        .onTap(self, action: #selector(buttonExchangeDidTouch)),
                    .spacer
                ])
                    .padding(.init(x: 20, y: 0)),
                BEStackViewSpacing(30)
            ], at: &index)
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
        
        @objc func buttonAddDidTouch() {
            buyAction?.execute()
        }
        
        @objc func buttonReceiveDidTouch() {
            receiveAction?.execute()
        }
        
        @objc func buttonSendDidTouch() {
            sendAction?.execute()
        }
        
        @objc func buttonExchangeDidTouch() {
            swapAction?.execute()
        }
    }
}
