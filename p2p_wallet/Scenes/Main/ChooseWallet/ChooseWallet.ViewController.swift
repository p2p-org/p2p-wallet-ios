//
//  ChooseWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import Foundation
import UIKit
import BECollectionView
import BEPureLayout

extension ChooseWallet {
    final class ViewController: BaseVC {
        
        // MARK: - Properties
        private let viewModel: ViewModel

        private lazy var rootView: RootView = {
            let rootView = RootView(viewModel: viewModel)
            rootView.forwardDelegate(to: self)
            return rootView
        }()

        // MARK: - Initializer
        init(title: String?, viewModel: ViewModel) {
            self.viewModel = viewModel

            super.init()

            self.title = title ?? L10n.selectToken
        }

        override func loadView() {
            view = UIStackView(
                axis: .vertical,
                spacing: 0,
                alignment: .fill,
                distribution: .fill,
                arrangedSubviews: [
                    NavigationBar(
                        title: title,
                        closeHandler: { [weak self] in
                            self?.dismiss(animated: true)
                        }
                    ),
                    UIView(height: 0.5, backgroundColor: .black.withAlphaComponent(0.3)),
                    rootView
                ]
            )
        }
    }
}

extension ChooseWallet.ViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let item = item as? Wallet else { return }
        viewModel.selectWallet(item)
        dismiss(animated: true, completion: nil)
    }
}
