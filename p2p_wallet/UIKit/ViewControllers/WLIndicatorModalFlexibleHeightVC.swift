//
//  WLIndicatorModalFlexibleHeightVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import Foundation
import UIKit

class FlexibleHeightNavigationController: UINavigationController, CustomPresentableViewController {
    var transitionManager: UIViewControllerTransitioningDelegate?

    func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        (visibleViewController as? CustomPresentableViewController)?
            .calculateFittingHeightForPresentedView(targetWidth: targetWidth)
            ?? .infinity
    }
}

class WLIndicatorModalFlexibleHeightVC: WLIndicatorModalVC, CustomPresentableViewController {
    // MARK: - Properties

    var transitionManager: UIViewControllerTransitioningDelegate?
    override var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    // MARK: - Subviews

    private lazy var titleLabel = UILabel(text: title, textSize: 17, weight: .semibold)
    private lazy var backButton = UIImageView(width: 10.72, height: 17.52, image: .backArrow, tintColor: .textBlack)
        .padding(.init(x: 6, y: 0))
        .onTap(self, action: #selector(back))
    private lazy var headerView: UIView = {
        let headerView = UIView(forAutoLayout: ())
        let stackView = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
            backButton
            titleLabel
        }
        headerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 20))
        let separator = UIView.defaultSeparator()
        headerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .init(all: 0), excludingEdge: .top)
        return headerView
    }()

    lazy var stackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
        headerView
    }

    // MARK: - Methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let nc = navigationController as? CustomPresentableViewController {
            nc.updatePresentationLayout(animated: animated)
        }
    }

    override func setUp() {
        super.setUp()
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        stackView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
    }

    func hideBackButton(_ isHidden: Bool = true) {
        backButton.isHidden = isHidden
    }

    // MARK: - Transition

    func updatePresentationLayout(animated: Bool = false) {
        // if this vc is embed in a CustomPresentableViewController navigation controller
        if let nc = navigationController as? CustomPresentableViewController {
            nc.updatePresentationLayout(animated: animated)
            return
        }

        // if not
        presentationController?.containerView?.setNeedsLayout()
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0.0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: 0.0,
                options: .allowUserInteraction,
                animations: {
                    self.presentationController?.containerView?.layoutIfNeeded()
                },
                completion: nil
            )
        } else {
            presentationController?.containerView?.layoutIfNeeded()
        }
    }

    override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        super.calculateFittingHeightForPresentedView(targetWidth: targetWidth) +
            containerView.fittingHeight(targetWidth: targetWidth) -
            view.safeAreaInsets.bottom
    }
}
