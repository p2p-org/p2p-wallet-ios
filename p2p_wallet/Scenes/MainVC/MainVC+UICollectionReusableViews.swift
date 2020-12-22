//
//  MainFooterView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

extension MainVC {
    class FirstSectionFooterView: SectionFooterView {
        lazy var button: UIView = {
            let view = UIView(backgroundColor: UIColor.black.withAlphaComponent(0.3), cornerRadius: 12)
            view.row([
                UILabel(text: L10n.allMyProducts, textSize: 17, weight: .medium, textColor: .white),
                UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .secondary)
            ], padding: .init(x: 20, y: 16))
            return view
        }()
        
        override func commonInit() {
            super.commonInit()
            stackView.alignment = .fill
            stackView.addArrangedSubview(button.padding(.init(x: .defaultPadding, y: 30)))
        }
    }
    
    class SecondSectionBackgroundView: SectionBackgroundView {
        override func commonInit() {
            super.commonInit()
            backgroundColor = .white
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            roundCorners([.topLeft, .topRight], radius: 20)
        }
    }
    
    class SecondSectionHeaderView: SectionHeaderView {
        override func commonInit() {
            super.commonInit()
            stackView.insertArrangedSubviews([
                UILabel(text: L10n.payments, textSize: 17, weight: .semibold)
                    .padding(.init(x: 20, y: 0)),
                UIView.row([
//                    createButton(image: .walletAdd, title: L10n.buy),
                    createButton(image: .walletReceive, title: L10n.receive),
                    createButton(image: .walletSend, title: L10n.send),
                    createButton(image: .walletSwap, title: L10n.exchange)
                ])
                    .padding(.init(x: 20, y: 0))
            ], at: 0, withCustomSpacings: [20, 30])
        }
        
        private func createButton(image: UIImage, title: String) -> UIStackView {
            let button = UIButton(width: 56, height: 56, backgroundColor: .f4f4f4, cornerRadius: 12, label: title, contentInsets: .init(all: 16))
            button.setImage(image, for: .normal)
            button.tintColor = .textBlack
            return UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill, arrangedSubviews: [
                button,
                UILabel(text: title, textSize: 12)
            ])
        }
    }
}
