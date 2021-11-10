//
//  BannersCollectionViewDataSource.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.11.2021.
//

import UIKit

extension Home {
    final class BannersCollectionViewDataSource: NSObject, UICollectionViewDataSource {
        var bannersContent: [BannerViewContent] = []

        init(collectionView: UICollectionView) {
            collectionView.register(
                BannerCollectionViewCell.self,
                forCellWithReuseIdentifier: BannerCollectionViewCell.reuseIdentifier
            )
        }

        func collectionView(
            _ collectionView: UICollectionView,
            numberOfItemsInSection section: Int
        ) -> Int {
            bannersContent.count
        }

        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: BannerCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? BannerCollectionViewCell else {
                assertionFailure("wrong cell")
                return UICollectionViewCell()
            }

            cell.setContent(bannersContent[indexPath.row])

            return cell
        }
    }
}
