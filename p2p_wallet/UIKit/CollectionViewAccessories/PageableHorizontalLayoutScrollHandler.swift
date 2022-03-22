//
//  PageableHorizontalLayoutScrollDelegate.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 29.10.2021.
//

import UIKit

final class PageableHorizontalLayoutScrollHandler {
    private var indexOfCellBeforeDragging = 0

    func collectionViewWillBeginDragging(
        _ collectionView: UICollectionView,
        layout: HorizontalFlowLayout
    ) {
        indexOfCellBeforeDragging = indexOfLeftCell(collectionView: collectionView, layout: layout)
    }

    func collectionViewWillEndDragging(
        _ collectionView: UICollectionView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>,
        layout: HorizontalFlowLayout
    ) {
        targetContentOffset.pointee = collectionView.contentOffset

        let indexOfLeftCell = self.indexOfLeftCell(collectionView: collectionView, layout: layout)

        let dataSourceCount = collectionView.numberOfItems(inSection: 0)
        let swipeVelocityThreshold: CGFloat = 0.5
        let hasEnoughVelocityToSlideToTheNextCell = indexOfCellBeforeDragging + 1 < dataSourceCount && velocity
            .x > swipeVelocityThreshold
        let hasEnoughVelocityToSlideToThePreviousCell = indexOfCellBeforeDragging - 1 >= 0 && velocity
            .x < -swipeVelocityThreshold
        let leftCellIsTheCellBeforeDragging = indexOfLeftCell == indexOfCellBeforeDragging
        let didUseSwipeToChangeCell = leftCellIsTheCellBeforeDragging &&
            (hasEnoughVelocityToSlideToTheNextCell || hasEnoughVelocityToSlideToThePreviousCell)

        if didUseSwipeToChangeCell {
            changeCellBySwipe(
                in: collectionView,
                toNextCell: hasEnoughVelocityToSlideToTheNextCell,
                layout: layout,
                xVelocity: velocity.x
            )
        } else {
            stabilizeScroll(
                in: collectionView,
                on: indexOfLeftCell,
                layout: layout
            )
        }
    }

    private func changeCellBySwipe(
        in collectionView: UICollectionView,
        toNextCell: Bool,
        layout: UICollectionViewFlowLayout,
        xVelocity: CGFloat
    ) {
        let snapToIndex = indexOfCellBeforeDragging + (toNextCell ? 1 : -1)
        let safeSnapToIndex = safeIndex(snapToIndex, in: collectionView)
        let x = CGFloat(safeSnapToIndex) * deduceItemWithSpacingSize(layout: layout)

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: xVelocity,
            options: .allowUserInteraction,
            animations: {
                collectionView.contentOffset = CGPoint(x: x, y: 0)
                collectionView.layoutIfNeeded()
            },
            completion: nil
        )
    }

    private func stabilizeScroll(
        in scrollView: UIScrollView,
        on index: Int,
        layout: UICollectionViewFlowLayout
    ) {
        let x = CGFloat(index) * deduceItemWithSpacingSize(layout: layout)

        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }

    private func indexOfLeftCell(
        collectionView: UICollectionView,
        layout: HorizontalFlowLayout
    ) -> Int {
        let itemsXDifference = deduceItemWithSpacingSize(layout: layout)
        let correctedOffset = collectionView.contentOffset.x - (layout.horisontalInset - layout.minimumLineSpacing)
        let floatIndex = correctedOffset / itemsXDifference
        let index = Int(round(floatIndex))

        return safeIndex(index, in: collectionView)
    }

    private func safeIndex(_ index: Int, in collectionView: UICollectionView) -> Int {
        let numberOfItems = collectionView.numberOfItems(inSection: 0)

        return max(0, min(numberOfItems - 1, index))
    }

    private func deduceItemWithSpacingSize(layout: UICollectionViewFlowLayout) -> CGFloat {
        layout.itemSize.width + layout.minimumLineSpacing
    }
}
