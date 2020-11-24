//
//  ChooseNewWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation

class AddNewWalletVC: WalletsVC<AddNewWalletVC.Cell> {
    lazy var titleLabel = UILabel(text: L10n.addCoin, textSize: 17, weight: .semibold)
    lazy var closeButton = UIButton.close(tintColor: .textBlack)
        .onTap(self, action: #selector(back))
    lazy var descriptionLabel = UILabel(text: L10n.AddATokenToYourWallet.ThisWillCost0._002039Sol, textSize: 15, textColor: .secondary, numberOfLines: 0)
    
    init(showInFullScreen: Bool = false) {
        let viewModel = ViewModel()
        super.init(viewModel: viewModel)
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
        let headerStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                titleLabel,
                closeButton
            ]),
            descriptionLabel
        ])
        
        view.addSubview(headerStackView)
        headerStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 25, left: 20, bottom: 0, right: 16), excludingEdge: .bottom)
        
        let separator = UIView.separator(height: 2, color: .vcBackground)
        view.addSubview(separator)
        separator.autoPinEdge(.top, to: .bottom, of: headerStackView, withOffset: 25)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        
        // disable refreshing
        collectionView.refreshControl = nil
        collectionView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        collectionView.autoPinEdge(.top, to: .bottom, of: separator)
    }
    
    override var sections: [Section] {
        [Section(headerTitle: "")]
    }
}

extension AddNewWalletVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        HalfSizePresentationController(presentedViewController: presented, presenting: presenting)
    }
}

extension AddNewWalletVC {
    class ViewModel: ListViewModel<Wallet> {
        override func reload() {
            // get static data
            var wallets = SolanaSDK.Token.getSupportedTokens(network: SolanaSDK.network)?.compactMap {$0 != nil ? Wallet(programAccount: $0!) : nil} ?? []
            
            for i in 0..<wallets.count {
                if let price = PricesManager.bonfida.prices.value.first(where: {$0.from == wallets[i].symbol}) {
                    wallets[i].price = price
                }
            }
            
            data = wallets
            state.accept(.loaded(data))
        }
        override func fetchNext() { /* do nothing */ }
    }
    
    class Cell: WalletCell {
        lazy var symbolLabel = UILabel(text: "SER", textSize: 17, weight: .bold)
        
        override func commonInit() {
            super.commonInit()
            
            coinLogoImageView.removeAllConstraints()
            coinLogoImageView.autoSetDimensions(to: CGSize(width: 44, height: 44))
            coinLogoImageView.layer.cornerRadius = 22
            
            coinNameLabel.font = .systemFont(ofSize: 12, weight: .medium)
            coinNameLabel.textColor = .secondary
            
            coinPriceLabel.font = .systemFont(ofSize: 17, weight: .bold)
            
            coinChangeLabel.font = .systemFont(ofSize: 12, weight: .medium)
            
            let button = UIButton(width: 32, height: 32, backgroundColor: .ededed, cornerRadius: 16, label: "+", labelFont: .systemFont(ofSize: 20), textColor: UIColor.textBlack.withAlphaComponent(0.5))
            
            stackView.alignment = .center
            stackView.addArrangedSubviews([
                coinLogoImageView,
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                        symbolLabel,
                        coinPriceLabel
                    ]),
                    UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                        coinNameLabel,
                        coinChangeLabel
                    ])
                ]),
                button
            ])
            
            stackView.constraintToSuperviewWithAttribute(.bottom)?.isActive = false
            let separator = UIView.separator(height: 2, color: .vcBackground)
            stackView.superview?.addSubview(separator)
            separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            separator.autoPinEdge(.top, to: .bottom, of: stackView, withOffset: 20)
        }
        
        override func setUp(with item: Wallet) {
            super.setUp(with: item)
            symbolLabel.text = item.symbol
        }
    }
}
