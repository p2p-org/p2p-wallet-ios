//
// Created by Giang Long Tran on 18.02.2022.
//

import BECollectionView
import Foundation
import RxSwift

extension Home {
    class BannerSection: BEStaticSectionsCollectionView.Section {
        private let disposeBag = DisposeBag()
        let onActionHandler: BECallback<Banners.Action>?

        init(index: Int, viewModel: BannerViewModel, onActionHandler: BECallback<Banners.Action>? = nil) {
            self.onActionHandler = onActionHandler
            super.init(
                index: index,
                layout: .init(
                    cellType: BannerCell.self,
                    interGroupSpacing: 2,
                    orthogonalScrollingBehavior: .groupPaging,
                    contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4),
                    sectionInsets: NSDirectionalEdgeInsets(top: 30, leading: 18, bottom: 30, trailing: 18),
                    horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(24),
                    customLayoutForGroupOnSmallScreen: { _ in
                        groupLayoutForFirstSection(width: 308, height: 142)
                    },
                    customLayoutForGroupOnLargeScreen: { _ in
                        groupLayoutForFirstSection(width: 308, height: 142)
                    }
                ),
                viewModel: viewModel
            )

            viewModel
                .dataDidChange
                .subscribe(onNext: { [weak self] in self?.collectionView?.reloadData(completion: {}) })
                .disposed(by: disposeBag)
        }

        override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: BECollectionViewItem) -> UICollectionViewCell {
            let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
            if let cell = cell as? BannerCell {
                cell.setUp(with: item.value)
                cell.onActionHandler = onActionHandler
            }
            return cell
        }
    }
}

private func groupLayoutForFirstSection(width: CGFloat, height: CGFloat) -> NSCollectionLayoutGroup {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(height))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    return group
}
