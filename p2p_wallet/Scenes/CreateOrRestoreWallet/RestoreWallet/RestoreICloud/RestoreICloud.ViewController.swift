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
        private let viewModel: RestoreWalletViewModelType
        
        // MARK: - Properties
        private let accountsListViewModel = AccountsListViewModel()
        
        // MARK: - Subviews
        lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.titleLabel.text = L10n.chooseYourWallet
            return navigationBar
        }()
        
        private lazy var walletsCollectionView: BEStaticSectionsCollectionView = .init(
            sections: [
                .init(
                    index: 0,
                    layout: .init(cellType: Cell.self),
                    viewModel: accountsListViewModel
                )
            ]
        )
        
        // MARK: - Initializer
        init(viewModel: RestoreWalletViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func viewDidLoad() {
            super.viewDidLoad()
            accountsListViewModel.reload()
        }
        
        override func setUp() {
            super.setUp()
            
            view.addSubview(navigationBar)
            navigationBar.autoPinEdge(toSuperviewSafeArea: .top)
            navigationBar.autoPinEdge(toSuperviewEdge: .leading)
            navigationBar.autoPinEdge(toSuperviewEdge: .trailing)
            
            view.addSubview(walletsCollectionView)
            walletsCollectionView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 0)
            walletsCollectionView.autoPinEdge(toSuperviewSafeArea: .leading)
            walletsCollectionView.autoPinEdge(toSuperviewSafeArea: .trailing)
            walletsCollectionView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 30)
            
            walletsCollectionView.delegate = self
        }
        
        override func bind() {
            super.bind()
            navigationBar.backButton.onTap(self, action: #selector(back))
        }
    }
}

extension RestoreICloud.ViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let account = item as? RestoreICloud.ParsedAccount else { return }
        viewModel.handleICloudAccount(account.account)
    }
}
