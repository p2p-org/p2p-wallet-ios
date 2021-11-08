//
//  BannersCollectionViewDelegate.swift
//  CollectionViewPeekingPages
//
//  Created by Andrew Vasiliev on 08.11.2021.
//  Copyright © 2021 Shai Balassiano. All rights reserved.
//

import UIKit

extension Home {
    final class BannersCollectionViewDelegate: NSObject, UICollectionViewDelegate {
        private let pageableScrollHandler: PageableHorizontalLayoutScrollHandler
        private let collectionView: UICollectionView
        private let layout: HorizontalFlowLayout

        init(
            collectionView: UICollectionView,
            layout: HorizontalFlowLayout,
            pageableScrollHandler: PageableHorizontalLayoutScrollHandler
        ) {
            self.collectionView = collectionView
            self.layout = layout
            self.pageableScrollHandler = pageableScrollHandler
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            pageableScrollHandler.collectionViewWillBeginDragging(collectionView, layout: layout)
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            pageableScrollHandler.collectionViewWillEndDragging(
                collectionView,
                withVelocity: velocity,
                targetContentOffset: targetContentOffset,
                layout: layout
            )
        }
    }
}
