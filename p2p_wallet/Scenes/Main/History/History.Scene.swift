//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import BEPureLayout
import Foundation
import UIKit

extension History {
    class Scene: BEScene {
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }

        let viewModel = SceneModel()

        override init() {
            super.init()

            // Start loading when wallets are ready.
            Resolver.resolve(WalletsRepository.self)
                .dataObservable
                .compactMap { $0 }
                .filter { $0?.count ?? 0 > 0 }
                .first()
                .subscribe(onSuccess: { [weak self] _ in self?.viewModel.reload() })
                .disposed(by: disposeBag)
        }

        override func build() -> UIView {
            BEVStack {
                // Navbar
                NewWLNavigationBar(initialTitle: L10n.history, separatorEnable: false)
                    .backIsHidden(true)

                // History
                NBENewDynamicSectionsCollectionView(
                    viewModel: viewModel,
                    mapDataToSections: { viewModel in
                        CollectionViewMappingStrategy.byData(
                            viewModel: viewModel,
                            forType: SolanaSDK.ParsedTransaction.self,
                            where: \SolanaSDK.ParsedTransaction.blockTime
                        ).reversed()
                    },
                    layout: .init(
                        header: .init(
                            viewClass: SectionHeaderView.self,
                            heightDimension: .estimated(15)
                        ),
                        cellType: Cell.self,
                        emptyCellType: WLEmptyCell.self,
                        numberOfLoadingCells: 7,
                        interGroupSpacing: 1,
                        itemHeight: .estimated(85)
                    ),
                    headerBuilder: { view, sectionInfo in
                        guard let view = view as? SectionHeaderView else { return }

                        if let date = sectionInfo?.userInfo as? String {
                            view.setUp(headerTitle: date)
                        } else {
                            // We have to have this text, otherwise the header cell will jump,
                            // because passing empty string will resize cell height
                            view.setUp(headerTitle: " ")
                        }
                    }
                )
            }
        }
    }
}
