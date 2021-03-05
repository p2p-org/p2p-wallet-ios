//
//  SwapChooseDestinationWalletViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2021.
//

import Foundation

class SwapChooseDestinationWalletViewController: ChooseWalletVC {
    override var sections: [CollectionViewSection] {
        [
            CollectionViewSection(
                header: .init(title: L10n.yourTokens, titleFont: .systemFont(ofSize: 15)),
                cellType: Cell.self,
                interGroupSpacing: 16
            ),
            CollectionViewSection(
                header: .init(title: L10n.allTokens, titleFont: .systemFont(ofSize: 15)),
                cellType: OtherTokenCell.self,
                interGroupSpacing: 16
            )
        ]
    }
    
    override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, Wallet> {
        var snapshot = NSDiffableDataSourceSnapshot<String, Wallet>()
        let section = sections.first?.header?.title ?? ""
        snapshot.appendSections([section])
        let allItems = viewModel.searchResult == nil ? filter(viewModel.items) : filter(viewModel.searchResult!)
        
        var yourItems = allItems.filter {$0.pubkey != nil}
        switch viewModel.state.value {
        case .loading:
            yourItems += [Wallet.placeholder(at: yourItems.count), Wallet.placeholder(at: yourItems.count + 1)]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(yourItems, toSection: section)
        
        let section2 = sections.last!.header!.title
        snapshot.appendSections([section2])
        let uncreatedItem = allItems.filter {$0.pubkey == nil}
        snapshot.appendItems(uncreatedItem, toSection: section2)
        return snapshot
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        if let header = headerForSection(0) as? SectionHeaderView {
            modifyHeaderFont(header)
        }
        
        if let header = headerForSection(1) as? SectionHeaderView {
            modifyHeaderFont(header)
        }
    }
    
    private func modifyHeaderFont(_ header: SectionHeaderView) {
        header.headerLabel.textColor = .textSecondary
    }
}

extension SwapChooseDestinationWalletViewController {
    class OtherTokenCell: Cell {
        override func setUp(with item: Wallet) {
            super.setUp(with: item)
            addressLabel.text = item.symbol
            
            equityValueLabel.isHidden = true
            tokenCountLabel.isHidden = true
        }
    }
}
