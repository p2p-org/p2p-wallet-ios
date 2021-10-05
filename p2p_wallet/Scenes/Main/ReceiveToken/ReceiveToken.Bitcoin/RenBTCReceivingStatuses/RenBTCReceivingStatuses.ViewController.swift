//
//  RenBTCReceivingStatuses.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import UIKit
import BECollectionView

extension RenBTCReceivingStatuses {
    class ViewController: WLIndicatorModalFlexibleHeightVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private var viewModel: RenBTCReceivingStatusesViewModelType
        
        // MARK: - Properties
        private lazy var collectionView: BEStaticSectionsCollectionView = .init(
            sections: [
                .init(
                    index: 0,
                    layout: .init(cellType: TxCell.self),
                    viewModel: viewModel
                )
            ]
        )
        
        // MARK: - Initializer
        init(viewModel: RenBTCReceivingStatusesViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            title = L10n.receivingStatus
            
            stackView.addArrangedSubview(collectionView)
            collectionView.delegate = self
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .detail(let txid):
                let vc = TxDetailViewController(viewModel: .init(receiveBitcoinViewModel: viewModel.receiveBitcoinViewModel, txid: txid))
                show(vc, sender: nil)
            case .none:
                break
            }
        }
        
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            .infinity
        }
    }
}

extension RenBTCReceivingStatuses.ViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let tx = item as? RenVM.LockAndMint.ProcessingTx else {return}
        viewModel.showDetail(txid: tx.tx.txid)
    }
}
