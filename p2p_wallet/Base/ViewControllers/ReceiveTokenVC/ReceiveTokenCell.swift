//
//  ReceiveTokenCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/11/2020.
//

import Foundation

class ReceiveTokenCell: BaseCollectionViewCell {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .center, distribution: .equalSpacing)
    lazy var qrCodeView = UIImageView(width: 150, height: 150, backgroundColor: .white)
    lazy var walletNameLabel = UILabel(textSize: 13, weight: .bold, textAlignment: .center)
    lazy var addressLabel = UILabel(textSize: 13, textColor: .secondary, numberOfLines: 0, textAlignment: .center)
    lazy var copyButton = DashedButton(title: L10n.copy)
    lazy var shareButton = DashedButton(title: L10n.share)
    
    override func commonInit() {
        super.commonInit()
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .buttonSub
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(all: 25))
        
        let buttonStackView: UIStackView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill)
            stackView.addArrangedSubviews([copyButton, shareButton])
            return stackView
        }()
        
        stackView.addArrangedSubview(qrCodeView)
        stackView.addArrangedSubview(walletNameLabel)
        stackView.addArrangedSubview(addressLabel)
        stackView.addArrangedSubview(buttonStackView)
    }
    
    func setUp(wallet: Wallet) {
        // TODO: qrcode
        walletNameLabel.text = wallet.name
        addressLabel.text = wallet.owner
    }
}
