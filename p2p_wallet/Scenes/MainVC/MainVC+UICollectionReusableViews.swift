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
            backgroundColor = .white
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            roundCorners([.topLeft, .topRight], radius: 20)
        }
    }
}
