//
//  BannersCollectionViewDataSource.swift
//  CollectionViewPeekingPages
//
//  Created by Andrew Vasiliev on 08.11.2021.
//  Copyright © 2021 Shai Balassiano. All rights reserved.
//

import UIKit

extension Home {
    final class BannersCollectionViewDataSource: NSObject, UICollectionViewDataSource {

        init(collectionView: UICollectionView) {
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        }

        func collectionView(
            _ collectionView: UICollectionView,
            numberOfItemsInSection section: Int
        ) -> Int {
            10
        }

        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
            cell.backgroundColor = .red

            return cell
        }
    }
}
