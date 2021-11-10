//
//  Home.BannerCollectionViewCell.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.11.2021.
//

import UIKit

final class BannerCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "BannerCollectionViewCell"

    var selectionHandler: (() -> Void)?
    private let bannerView = WLBannerView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureSelf()
        setConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(_ content: BannerViewContent) {
        bannerView.titleText = content.title
        bannerView.descriptionText = content.description
        bannerView.closeButtonCompletion = content.closeHandler
        selectionHandler = content.selectionHandler
    }

    private func configureSelf() {
        addSubview(bannerView)
    }

    private func setConstraints() {
        bannerView.autoPinEdgesToSuperviewEdges()
    }
}
