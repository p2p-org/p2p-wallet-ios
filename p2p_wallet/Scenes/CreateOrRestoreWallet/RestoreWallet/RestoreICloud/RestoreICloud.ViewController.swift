//
//  RestoreICloud.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/09/2021.
//

import BECollectionView
import Foundation
import UIKit

extension RestoreICloud {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: RestoreWalletViewModelType

        // MARK: - Properties

        private let accountsListViewModel = AccountsListViewModel()

        // MARK: - Subviews

        private lazy var walletsCollectionView: BEStaticSectionsCollectionView = .init(
            sections: [
                .init(
                    index: 0,
                    layout: .init(cellType: Cell.self),
                    viewModel: accountsListViewModel
                ),
            ]
        )

        // MARK: - Initializer

        init(viewModel: RestoreWalletViewModelType) {
            self.viewModel = viewModel
            super.init()
            navigationItem.title = L10n.chooseYourWallet
        }

        // MARK: - Methods

        override func viewDidLoad() {
            super.viewDidLoad()
            accountsListViewModel.reload()
        }

        override func setUp() {
            super.setUp()

            view.addSubview(walletsCollectionView)
            walletsCollectionView.autoPinEdge(toSuperviewSafeArea: .top)
            walletsCollectionView.autoPinEdge(toSuperviewSafeArea: .leading)
            walletsCollectionView.autoPinEdge(toSuperviewSafeArea: .trailing)
            walletsCollectionView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 30)

            walletsCollectionView.delegate = self
        }
    }
}

// MARK: - BECollectionViewDelegate

extension RestoreICloud.ViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView _: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let account = item as? RestoreICloud.ParsedAccount else { return }
        viewModel.handleICloudAccount(account.account)
    }
}
