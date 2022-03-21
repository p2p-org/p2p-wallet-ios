//
//  HorizontalFlowLayout.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 29.10.2021.
//

import UIKit

final class HorizontalFlowLayout: UICollectionViewFlowLayout {
    private let maxCellWidth: CGFloat
    private let verticalInset: CGFloat
    let horisontalInset: CGFloat

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }

        configureCellSizes(collectionView: collectionView)
    }

    init(
        horisontalInset: CGFloat,
        verticalInset: CGFloat,
        spacing: CGFloat,
        maxCellWidth: CGFloat = .infinity
    ) {
        self.horisontalInset = horisontalInset
        self.maxCellWidth = maxCellWidth
        self.verticalInset = verticalInset

        super.init()

        configureSelf(lineSpacing: spacing)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    private func configureSelf(lineSpacing: CGFloat) {
        minimumLineSpacing = lineSpacing
        scrollDirection = .horizontal
    }

    private func configureCellSizes(collectionView: UICollectionView) {
        let collectionViewFrameSize = collectionView.frame.size

        sectionInset = UIEdgeInsets(
            top: verticalInset,
            left: horisontalInset,
            bottom: verticalInset,
            right: horisontalInset
        )

        itemSize = CGSize(
            width: min(maxCellWidth, collectionViewFrameSize.width - horisontalInset * 2),
            height: collectionViewFrameSize.height - verticalInset * 2
        )
    }
}
