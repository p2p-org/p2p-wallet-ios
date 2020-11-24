//
//  ChooseWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation

class ChooseWalletVC: MyWalletsVC<ChooseWalletVC.Cell> {
    let closeButton = UIButton.close(tintColor: .textBlack)
        .onTap(self, action: #selector(back))
    
    override func setUp() {
        super.setUp()
        collectionView.addSubview(closeButton)
        closeButton.autoPinToTopRightCornerOfSuperviewSafeArea(xInset: 16, yInset: 8)
    }
    
    // MARK: - Layouts
    override var sections: [Section] {
        [Section(headerTitle: L10n.yourWallets)]
    }
}

extension ChooseWalletVC {
    class Cell: WalletCell {
        override func commonInit() {
            super.commonInit()
            stackView.spacing = 20
            stackView.alignment = .center
            coinLogoImageView.removeAllConstraints()
            coinLogoImageView.autoSetDimensions(to: CGSize(width: 55, height: 55))
            coinLogoImageView.layer.cornerRadius = 55/2
            coinLogoImageView.layer.masksToBounds = true
            coinNameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            equityValueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            tokenCountLabel.font = .systemFont(ofSize: 15)
            stackView.addArrangedSubviews([
                coinLogoImageView,
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [coinNameLabel, equityValueLabel]),
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [.spacer, tokenCountLabel])
                ])
            ])
        }
    }
}
