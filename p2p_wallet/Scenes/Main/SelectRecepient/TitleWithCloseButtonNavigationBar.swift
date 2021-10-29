//
//  TitleWithCloseButtonNavigationBar.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 22.10.2021.
//

import PureLayout
import RxSwift
import UIKit

final class TitleWithCloseButtonNavigationBar: UIStackView {
    private let padding = UIView()
    private let titleLabel = UILabel(textSize: 17, weight: .semibold)
    private let closeButton = UIButton(
        label: L10n.close,
        labelFont: .systemFont(ofSize: 17, weight: .medium),
        textColor: .h5887ff,
        contentInsets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    )

    var closeObservable: Observable<Void> {
        closeButton.rx.tap.asObservable()
    }

    init(title: String) {
        super.init(frame: .zero)

        configureSelf()
        configureSubviews()
        setConstraints()

        self.titleLabel.text = title
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(text: String) {
        titleLabel.text = text
    }

    private func configureSelf() {
        axis = .horizontal
        spacing = 0
        alignment = .fill
        distribution = .fill

        [padding, titleLabel, closeButton].forEach(addArrangedSubview)
    }

    private func configureSubviews() {
        closeButton.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func setConstraints() {
        padding.autoSetDimension(.width, toSize: 20)
        autoSetDimension(.height, toSize: 60)
    }
}
