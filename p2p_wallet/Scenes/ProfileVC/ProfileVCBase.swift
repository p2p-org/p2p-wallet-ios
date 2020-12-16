//
//  ProfileVCBase.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation

class ProfileVCBase: WLCenterSheet {
    override var padding: UIEdgeInsets {.init(all: 20)}
    
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubview(createHeaderView())
    }
    
    func createHeaderView() -> UIStackView {
        UIView.row([
            UIView.row([
                UIImageView(width: 4.5, height: 9, image: .backArrow, tintColor: .textBlack),
                UILabel(text: L10n.back, textSize: 17, textColor: .secondary)
            ])
                .with(spacing: 8)
                .onTap(self, action: #selector(back)),
            UILabel(text: title, textSize: 17, weight: .bold),
            UIButton(label: L10n.done, labelFont: .systemFont(ofSize: 17), textColor: .secondary)
                .onTap(self, action: #selector(back))
        ]).with(alignment: .fill, distribution: .equalCentering)
    }
}
