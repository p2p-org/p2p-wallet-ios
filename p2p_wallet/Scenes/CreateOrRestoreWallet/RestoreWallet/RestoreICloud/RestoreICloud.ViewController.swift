//
//  RestoreICloud.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import Foundation
import UIKit
import BECollectionView

extension RestoreICloud {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: RestoreWalletViewModelType
        
        // MARK: - Properties
        private let accountsListViewModel = AccountsListViewModel()
        
        // MARK: - Subviews
        private lazy var headerView = UIStackView(axis: .vertical, spacing: 20, alignment: .leading, distribution: .fill) {
            UIImageView(width: 36, height: 36, image: .backSquare)
                .onTap(self, action: #selector(back))
            BEStackViewSpacing(30)
            UILabel(text: L10n.chooseWallet, textSize: 27, weight: .bold, numberOfLines: 0)
            BEStackViewSpacing(8)
            UILabel(text: L10n.multipleWalletsFound, textColor: .textSecondary, numberOfLines: 0)
        }
        
        private lazy var walletsCollectionView: BEStaticSectionsCollectionView = .init(
            sections: [
                .init(
                    index: 0,
                    layout: .init(cellType: Cell.self),
                    viewModel: accountsListViewModel
                )
            ]
        )
        
        override func viewDidLoad() {
            super.viewDidLoad()
            accountsListViewModel.reload()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            view.addSubview(headerView)
            headerView.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .bottom)
            
            view.addSubview(walletsCollectionView)
            walletsCollectionView.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: 30)
            walletsCollectionView.autoPinEdge(toSuperviewSafeArea: .leading)
            walletsCollectionView.autoPinEdge(toSuperviewSafeArea: .trailing)
            walletsCollectionView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 30)
            
            walletsCollectionView.delegate = self
        }
    }
}

extension RestoreICloud.ViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let account = item as? RestoreICloud.ParsedAccount else {return}
        viewModel.handlePhrases(account.account.phrase.components(separatedBy: " "))
    }
}
