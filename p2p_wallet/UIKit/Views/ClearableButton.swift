//
//  ClearableButton.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 12.11.2021.
//

import UIKit

final class ClearButton: UIButton {
    private let image = UIImageView()

    let imageSize = CGSize(width: 17, height: 17)

    init() {
        super.init(frame: .zero)

        configureSubviews()
        addSubviews()
        setConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        image.image = .crossIcon
    }

    private func addSubviews() {
        addSubview(image)
    }

    private func setConstraints() {
        image.autoSetDimensions(to: imageSize)
        image.autoCenterInSuperview()
    }
}
