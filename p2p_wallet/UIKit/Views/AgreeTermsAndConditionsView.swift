//
//  AgreeTermsAndConditionsView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 19.11.2021.
//

import UIKit

final class AgreeTermsAndConditionsView: UIView {
    private let topText = UILabel()
    private let bottomText = UILabel()

    var didTouchHyperLink: (() -> Void)?

    init() {
        super.init(frame: .zero)

        configureSubviews()
        addSubviews()
        setConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        topText.textAlignment = .center
        topText.font = .systemFont(ofSize: 13, weight: .regular)
        topText.text = L10n.byContinuingYouAgreeToWalletS

        bottomText.textAlignment = .center
        bottomText.font = .systemFont(ofSize: 13, weight: .regular)
        bottomText.textColor = .h5887ff
        bottomText.text = L10n.capitalizedTermsAndConditions
        bottomText.onTap(self, action: #selector(hyperLinkTapped))
    }

    private func addSubviews() {
        addSubview(topText)
        addSubview(bottomText)
    }

    private func setConstraints() {
        topText.autoSetDimension(.height, toSize: 18)
        topText.autoPinEdgesToSuperviewEdges(with: .zero,excludingEdge: .bottom)

        bottomText.autoSetDimension(.height, toSize: 18)
        bottomText.autoPinEdge(.top, to: .bottom, of: topText)
        bottomText.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }

    @objc
    private func hyperLinkTapped() {
        didTouchHyperLink?()
    }
}
