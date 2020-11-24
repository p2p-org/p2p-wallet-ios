//
//  ChooseNewWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/11/2020.
//

import Foundation

class AddNewWalletVC: WalletsVC<AddNewWalletVC.Cell> {
    init() {
        let viewModel = ViewModel()
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        // disable refreshing
        collectionView.refreshControl = nil
    }
    
    override var sections: [Section] {
        [Section(headerTitle: "")]
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
        }
        
        override func setUp(with item: Wallet) {
            super.setUp(with: item)
            symbolLabel.text = item.symbol
        }
    }
}
