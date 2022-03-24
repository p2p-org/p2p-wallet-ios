//
//  WLModalViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2021.
//

import Foundation
import UIKit

class WLModalViewController: BaseVC, CustomPresentableViewController {
    var transitionManager: UIViewControllerTransitioningDelegate?

    // MARK: - Properties

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var originalPosition: CGPoint!
//    private var currentPositionTouched: CGPoint!
//    var canSwipeToDismiss: Bool = true {
//        didSet {
//            panGestureRecognizer.isEnabled = canSwipeToDismiss
//        }
//    }

    var dismissCompletion: (() -> Void)?

    // MARK: - Subviews

    private var child: UIView!

    // MARK: - Methods

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.roundCorners([.topLeft, .topRight], radius: 18)
    }

    override func setUp() {
        super.setUp()

        // indicator
        let indicator = UIView(width: 31, height: 4, backgroundColor: .d1d1d6, cornerRadius: 2)
        view.addSubview(indicator)
        indicator.autoPinEdge(toSuperviewEdge: .top, withInset: 6)
        indicator.autoAlignAxis(toSuperviewAxis: .vertical)

        // child
        child = build()
        view.addSubview(child)
        child.autoPinEdge(.top, to: .bottom, of: indicator, withOffset: 6)
        child.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)

        layout()

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
    }

    func layout() {}

    func build() -> UIView {
        fatalError("build method is not implemented")
    }

    func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        6 + 4 + 6 + child.fittingHeight(targetWidth: targetWidth)
    }

    @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let view = panGesture.view!
        let translation = panGesture.translation(in: view)

        switch panGesture.state {
        case .began:
            originalPosition = view.center
//            currentPositionTouched = panGesture.location(in: view)
        case .changed:
            guard translation.y > 0 else { break }
            var newPosition = originalPosition
            newPosition!.y += translation.y
            view.center = newPosition!
        case .ended:
            if translation.y >= 100 {
                UIView.animate(withDuration: 0.2) {
                    self.view.frame.origin = CGPoint(
                        x: self.view.frame.origin.x,
                        y: 2000
                    )
                } completion: { isCompleted in
                    if isCompleted {
                        self.dismiss(animated: false, completion: self.dismissCompletion)
                    }
                }
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.center = self.originalPosition
                })
            }
        default:
            break
        }
    }
}
