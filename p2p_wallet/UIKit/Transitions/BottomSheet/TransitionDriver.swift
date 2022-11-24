//
//  TransitionDriver.swift
//  p2p_wallet
//
//  Created by Ivan on 19.08.2022.
//

import UIKit

class TransitionDriver: UIPercentDrivenInteractiveTransition {
    // MARK: - Linking

    func link(to controller: UIViewController) {
        presentedController = controller

        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handle(recognizer:)))
        presentedController?.view.addGestureRecognizer(panRecognizer!)
        panRecognizer?.delegate = self
    }

    private weak var presentedController: UIViewController?
    private var panRecognizer: UIPanGestureRecognizer?

    // MARK: - Override

    override var wantsInteractiveStart: Bool {
        get {
            switch direction {
            case .present:
                return false
            case .dismiss:
                let gestureIsActive = panRecognizer?.state == .began
                return gestureIsActive
            }
        }

        set {}
    }

    // MARK: - Direction

    var direction: TransitionDirection = .present

    @objc private func handle(recognizer r: UIPanGestureRecognizer) {
        switch direction {
        case .present:
            handlePresentation(recognizer: r)
        case .dismiss:
            handleDismiss(recognizer: r)
        }
    }
}

// MARK: - Gesture Handling

extension TransitionDriver {
    private func handlePresentation(recognizer r: UIPanGestureRecognizer) {
        switch r.state {
        case .began:
            pause()
        case .changed:
            let increment = -r.incrementToBottom(maxTranslation: maxTranslation)
            update(percentComplete + increment)
        case .ended, .cancelled:
            if r.isProjectedToDownHalf(maxTranslation: maxTranslation) {
                cancel()
            } else {
                finish()
            }
        case .failed:
            cancel()
        default:
            break
        }
    }

    private func handleDismiss(recognizer r: UIPanGestureRecognizer) {
        switch r.state {
        case .began:
            pause() // Pause allows to detect isRunning

            if !isRunning {
                presentedController?.dismiss(animated: true) // Start the new one
            }
        case .changed:
            update(percentComplete + r.incrementToBottom(maxTranslation: maxTranslation))
        case .ended, .cancelled:
            if r.isProjectedToDownHalf(maxTranslation: maxTranslation) {
                finish()
            } else {
                cancel()
            }
        case .failed:
            cancel()
        default:
            break
        }
    }

    var maxTranslation: CGFloat {
        presentedController?.view.frame.height ?? 0
    }

    /// `pause()` before call `isRunning`
    private var isRunning: Bool {
        percentComplete != 0
    }
}

private extension UIPanGestureRecognizer {
    func isProjectedToDownHalf(maxTranslation: CGFloat) -> Bool {
        let endLocation = projectedLocation(decelerationRate: .fast)
        let isPresentationCompleted = endLocation.y > maxTranslation / 2
        return isPresentationCompleted
    }

    func incrementToBottom(maxTranslation: CGFloat) -> CGFloat {
        let translation = self.translation(in: view).y
        setTranslation(.zero, in: nil)

        let percentIncrement = translation / maxTranslation
        return percentIncrement
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TransitionDriver: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if gestureRecognizer == panRecognizer, !(otherGestureRecognizer is UIPanGestureRecognizer) {
            return true
        }
        return false
    }
}
