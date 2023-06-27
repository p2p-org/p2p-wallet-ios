//
//  WLLoadingIndicatorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/03/2021.
//

import Foundation
import KeyAppUI

extension UIView {
    @discardableResult
    func showLoadingIndicatorView(isBlocking: Bool = true) -> WLLoadingIndicatorView {
        hideLoadingIndicatorView()

        let indicator = WLLoadingIndicatorView(isBlocking: isBlocking)
        addSubview(indicator)
        indicator.autoPinEdgesToSuperviewEdges()
        return indicator
    }

    func hideLoadingIndicatorView() {
        subviews.first(where: { $0 is WLLoadingIndicatorView })?.removeFromSuperview()
    }
}

class WLLoadingIndicatorView: BEView {
    // MARK: - Properties

    private let isBlocking: Bool

    // MARK: - Subviews

    private lazy var spinner = CircularProgressIndicator(
        backgroundCircularColor: Asset.Colors.night.color.withAlphaComponent(0.6),
        foregroundCircularColor: Asset.Colors.night.color
    )

    // MARK: - Initializer

    init(isBlocking: Bool) {
        self.isBlocking = isBlocking
        super.init(frame: .zero)
        configureForAutoLayout()
    }

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        isUserInteractionEnabled = isBlocking

        addSubview(spinner)
        spinner.autoSetDimensions(to: CGSize(width: 27, height: 27))
        spinner.autoCenterInSuperview()
    }
}
