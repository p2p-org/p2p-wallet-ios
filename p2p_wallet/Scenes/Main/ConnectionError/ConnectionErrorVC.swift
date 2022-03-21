//
//  ConnectionErrorVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/05/2021.
//

import Action
import Foundation

extension UIView {
    @discardableResult
    func showConnectionErrorView(refreshAction: CocoaAction? = nil) -> ConnectionErrorView {
        hideConnectionErrorView()

        let errorView = ConnectionErrorView()
        errorView.refreshAction = refreshAction
        addSubview(errorView)
        errorView.autoPinEdgesToSuperviewEdges()
        return errorView
    }

    func hideConnectionErrorView() {
        subviews.first(where: { $0 is ConnectionErrorView })?.removeFromSuperview()
    }
}

class ConnectionErrorView: BEView {
    // MARK: - Subviews

    private lazy var refreshButton = WLButton.stepButton(
        enabledColor: .eff3ff,
        textColor: .h5887ff,
        label: L10n.refresh
    )

    private lazy var contentView: UIView = {
        let view = UIView(backgroundColor: .white)
        let imageView = UIImageView(width: 65, height: 65, image: .connectionError)
        let stackView = UIStackView(axis: .vertical, alignment: .fill, distribution: .fill) {
            imageView.centeredHorizontallyView

            BEStackViewSpacing(30)

            UILabel(text: L10n.connectionProblem, textSize: 21, weight: .semibold, textAlignment: .center)

            BEStackViewSpacing(5)

            UILabel(
                text: L10n.yourConnectionToTheInternetHasBeenInterrupted,
                textSize: 17,
                weight: .medium,
                textColor: .textSecondary,
                numberOfLines: 0,
                textAlignment: .center
            )

            BEStackViewSpacing(66)

            refreshButton
        }

        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 30))

        // separator
        let separator = UIView.defaultSeparator()
        view.addSubview(separator)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        separator.autoAlignAxis(.horizontal, toSameAxisOf: imageView)
        return view
    }()

    var refreshAction: CocoaAction? {
        didSet {
            refreshButton.rx.action = refreshAction
        }
    }

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        // dimming view
        let dimmingView = UIView(backgroundColor: .black.withAlphaComponent(0.5))
        addSubview(dimmingView)
        dimmingView.autoPinEdgesToSuperviewEdges()

        // content view
        addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.roundCorners([.topLeft, .topRight], radius: 20)
    }
}
