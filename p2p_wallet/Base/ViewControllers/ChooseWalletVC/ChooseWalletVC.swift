//
//  ChooseWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation

class ChooseWalletVC: MyWalletsVC<ChooseWalletVC.Cell> {
    let titleLabel = UILabel(text: L10n.yourWallets, textSize: 17, weight: .semibold)
    let closeButton = UIButton.close(tintColor: .textBlack)
        .onTap(self, action: #selector(back))
    
    var completion: ((Wallet) -> Void)?
    
    init(showInFullScreen: Bool = false) {
        super.init()
        if !showInFullScreen {
            modalPresentationStyle = .custom
            transitioningDelegate = self
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        let headerStackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
            titleLabel,
            closeButton
        ])
        view.addSubview(headerStackView)
        headerStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16), excludingEdge: .bottom)
        
        collectionView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        collectionView.autoPinEdge(.top, to: .bottom, of: headerStackView, withOffset: 8)
    }
    
    // MARK: - Layouts
    override var sections: [Section] {
        [Section(headerTitle: "")]
    }
    
    // MARK: - Delegate
    override func itemDidSelect(_ item: Wallet) {
        completion?(item)
    }
}

extension ChooseWalletVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        HalfSizePresentationController(presentedViewController: presented, presenting: presenting)
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
