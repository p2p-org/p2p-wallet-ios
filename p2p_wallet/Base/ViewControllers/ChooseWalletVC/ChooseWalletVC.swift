//
//  ChooseWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation

class ChooseWalletVC: WLModalWrapperVC, UIViewControllerTransitioningDelegate {
    override var padding: UIEdgeInsets {super.padding.modifying(dLeft: .defaultPadding, dRight: .defaultPadding)}
    
    var completion: ((Wallet) -> Void)? {
        get {
            (vc as! _ChooseWalletVC).completion
        }
        set {
            (vc as! _ChooseWalletVC).completion = newValue
        }
    }
    
    init(
        showInFullScreen: Bool = false,
        customFilter: @escaping ((Wallet) -> Bool) = {$0.symbol == "SOL" || $0.amount > 0}
    ) {
        let vc = _ChooseWalletVC(showInFullScreen: showInFullScreen, customFilter: customFilter)
        super.init(wrapped: vc)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    override func setUp() {
        title = L10n.selectWallet
        super.setUp()
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        ExpandablePresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class _ChooseWalletVC: MyWalletsVC {
    var completion: ((Wallet) -> Void)?
    let customFilter: ((Wallet) -> Bool)
    
    init(showInFullScreen: Bool = false, customFilter: @escaping ((Wallet) -> Bool)) {
        self.customFilter = customFilter
        super.init()
        if !showInFullScreen {
            modalPresentationStyle = .custom
            transitioningDelegate = self
        }
    }
    
    override func filter(_ items: [Wallet]) -> [Wallet] {
        items.filter {customFilter($0)}
    }
    
    // MARK: - Layouts
    override var sections: [Section] {
        [
            Section(
                header: Section.Header(title: ""),
                cellType: Cell.self,
                interGroupSpacing: 16
            )
        ]
    }
    
    // MARK: - Delegate
    override func itemDidSelect(_ item: Wallet) {
        completion?(item)
    }
}

extension _ChooseWalletVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        HalfSizePresentationController(presentedViewController: presented, presenting: presenting)
    }
}

extension _ChooseWalletVC {
    class Cell: WalletCell {
        override var loadingViews: [UIView] {super.loadingViews + [addressLabel]}
        lazy var addressLabel = UILabel(textSize: 13, textColor: .textSecondary)
        
        override func commonInit() {
            super.commonInit()
            stackView.alignment = .center
            stackView.constraintToSuperviewWithAttribute(.bottom)?
                .constant = -16
            
            coinNameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            coinNameLabel.numberOfLines = 1
            equityValueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            tokenCountLabel.font = .systemFont(ofSize: 13)
            
            stackView.addArrangedSubviews([
                coinLogoImageView,
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [coinNameLabel, equityValueLabel]),
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [addressLabel, tokenCountLabel])
                ])
            ])
        }
        
        override func setUp(with item: Wallet) {
            super.setUp(with: item)
            if let pubkey = item.pubkey {
                addressLabel.text = pubkey.prefix(4) + "..." + pubkey.suffix(4)
            }
        }
    }
}
