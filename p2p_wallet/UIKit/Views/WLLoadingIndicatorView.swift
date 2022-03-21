//
//  WLLoadingIndicatorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/03/2021.
//

import Foundation

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

    private lazy var spinner = WLSpinnerView(size: 65, endColor: .h5887ff)

    // MARK: - Initializer

    init(isBlocking: Bool) {
        self.isBlocking = isBlocking
        super.init(frame: .zero)
        configureForAutoLayout()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        animate()
    }

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        isUserInteractionEnabled = isBlocking

        addSubview(spinner)
        spinner.autoCenterInSuperview()
    }

    func animate() {
        spinner.animate()
    }
}
