//
//  RenBTCReceivingStatuses.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import UIKit
import BECollectionView
import RenVMSwift

extension RenBTCReceivingStatuses {
    class NewViewController: BEScene {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private var viewModel: RenBTCReceivingStatusesViewModelType
        
        init(viewModel: RenBTCReceivingStatusesViewModelType) {
            self.viewModel = viewModel
            super.init()
            
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }
        
        override func build() -> UIView {
            BESafeArea {
                UIStackView(axis: .vertical, alignment: .fill) {
                    NewWLNavigationBar(initialTitle: L10n.receivingStatuses, separatorEnable: false)
                        .onBack { [unowned self] in self.back() }
                        .setupWithType(NewWLNavigationBar.self) { view in
                            viewModel.processingTxsDriver
                                .map { txs in L10n.statusesReceived(txs.count) }
                                .drive(view.titleLabel.rx.text)
                                .disposed(by: disposeBag)
                        }
                    NBENewDynamicSectionsCollectionView(
                        viewModel: viewModel,
                        mapDataToSections: { viewModel in
                            CollectionViewMappingStrategy.byData(
                                viewModel: viewModel,
                                forType: RenVM.LockAndMint.ProcessingTx.self,
                                where: \RenVM.LockAndMint.ProcessingTx.submittedAt
                            )
                        },
                        layout: .init(
                            header: .init(
                                viewClass: SectionHeaderView.self,
                                heightDimension: .estimated(15)
                            ),
                            cellType: TxCell.self,
                            emptyCellType: WLEmptyCell.self,
                            interGroupSpacing: 1,
                            itemHeight: .estimated(85)
                        ),
                        headerBuilder: { (view, section) in
                            guard let view = view as? SectionHeaderView else { return }
                            guard let section = section else {
                                view.setUp(headerTitle: "")
                                return
                            }
                            
                            let date = section.userInfo as? Date ?? Date()
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .medium
                            dateFormatter.timeStyle = .none
                            dateFormatter.locale = Locale.shared
                            
                            view.setUp(
                                headerTitle: dateFormatter.string(from: date),
                                headerFont: UIFont.systemFont(ofSize: 12),
                                textColor: .secondaryLabel
                            )
                        }
                    ).withDelegate(self)
                }
            }
        }
    }
    
    class ViewController: WLIndicatorModalFlexibleHeightVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private var viewModel: RenBTCReceivingStatusesViewModelType
        private var cellsHeight: CGFloat = 0
        
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
            title = L10n.receivingStatuses
            
            stackView.addArrangedSubview(collectionView)
            collectionView.delegate = self
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
            
            viewModel.processingTxsDriver
                .drive(onNext: { [weak self] txs in
                    self?.cellsHeight = CGFloat(txs.count) * 72
                    self?.updatePresentationLayout(animated: true)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .detail(let txid):
                let vc = TxDetailViewController(viewModel: .init(processingTxsDriver: viewModel.processingTxsDriver, txid: txid))
                show(vc, sender: nil)
            case .none:
                break
            }
        }
        
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            super.calculateFittingHeightForPresentedView(targetWidth: targetWidth) +
                cellsHeight
        }
    }
}

extension RenBTCReceivingStatuses.NewViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let tx = item as? RenVM.LockAndMint.ProcessingTx else { return }
        viewModel.showDetail(txid: tx.tx.txid)
    }
    
    private func navigate(to scene: RenBTCReceivingStatuses.NavigatableScene?) {
        switch scene {
        case .detail(let txid):
            let vc = RenBTCReceivingStatuses.TxDetailViewController(viewModel: .init(processingTxsDriver: viewModel.processingTxsDriver, txid: txid))
            show(vc, sender: nil)
        case .none:
            break
        }
    }
}

extension RenBTCReceivingStatuses.ViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let tx = item as? RenVM.LockAndMint.ProcessingTx else { return }
        viewModel.showDetail(txid: tx.tx.txid)
    }
}
