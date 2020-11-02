//
//  WCVHeaderView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

class WCVSectionHeaderView: UICollectionReusableView {
    lazy var stackView = UIStackView(axis: .vertical, spacing: 30, alignment: .center, distribution: .fill)
    
    lazy var headerLabel = UILabel(text: "Wallets", textSize: 17, weight: .bold)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        stackView.addArrangedSubview(headerLabel)
        headerLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor)
            .isActive = true
    }
}

class WCVFirstSectionHeaderView: WCVSectionHeaderView {
    lazy var priceLabel = UILabel(text: "$120,00", textSize: 36, weight: .semibold, textAlignment: .center)
    lazy var priceChangeLabel = UILabel(text: "+ 0,16 US$ (0,01%) 24 hrs", textSize: 15, textColor: UIColor.textBlack.withAlphaComponent(0.5), numberOfLines: 0, textAlignment: .center)
    
    lazy var sendButton = createButton(title: L10n.send)
    lazy var receiveButton = createButton(title: L10n.receive)
    lazy var swapButton = createButton(title: L10n.swap)
    
    override func commonInit() {
        let qrStackView: UIStackView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 25, alignment: .center, distribution: .fill)
            stackView.addArrangedSubview(
                UIImageView(
                    width: 25,
                    height: 25,
                    backgroundColor: UIColor.textBlack.withAlphaComponent(0.5),
                    image: .scanQr
                )
            )
            stackView.addArrangedSubview(
                UILabel(
                    text: L10n.slideToScan,
                    textSize: 13,
                    weight: .semibold,
                    textColor: UIColor.textBlack.withAlphaComponent(0.5)
                )
            )
            stackView.addArrangedSubview(.spacer)
            return stackView
        }()
        
        let buttonsStackView = UIStackView(axis: .horizontal, spacing: 2, alignment: .fill, distribution: .fill)
        buttonsStackView.addArrangedSubviews([sendButton, receiveButton, swapButton])
        
        headerLabel.removeFromSuperview()
        
        stackView.addArrangedSubviews([
            qrStackView,
            priceLabel,
            priceChangeLabel,
            buttonsStackView,
            headerLabel
        ])
    }
    
    // MARK: - Helpers
    func createButton(title: String) -> UIView {
        let view = UIView(height: 56, backgroundColor: .textBlack)
        let label = UILabel(text: title, textSize: 15, weight: .semibold, textColor: .textWhite, textAlignment: .center)
        view.addSubview(label)
        label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        return view
    }
}
