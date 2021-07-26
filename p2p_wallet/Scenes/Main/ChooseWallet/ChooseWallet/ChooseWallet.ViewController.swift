//
//  ChooseWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import Foundation
import UIKit
import BECollectionView

extension ChooseWallet {
    class ViewController: WLIndicatorModalVC {
        
        // MARK: - Properties
        private let viewModel: ViewModel
        private lazy var rootView: RootView = {
            let rootView = RootView(viewModel: viewModel)
            rootView.forwardDelegate(to: self)
            return rootView
        }()
        
        // MARK: - Initializer
        init(viewModel: ViewModel)
        {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill, arrangedSubviews: [
                    UILabel(text: L10n.selectToken, textSize: 17, weight: .semibold),
                    UILabel(text: L10n.close, textSize: 17, textColor: .h5887ff)
                        .onTap(self, action: #selector(back))
                ])
                    .padding(.init(all: 20)),
                UIView.defaultSeparator(),
                rootView
            ])
            
            containerView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }
        
        override func bind() {
            super.bind()
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
