// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import UIKit

enum OldSmartCoordinatorError {
    case unsupportedPresentingViewController
}

protocol OldSmartCoordinatorPresentation {
    var presentingViewController: UIViewController { get }

    func run(presentedViewController: UIViewController)
}

class OldSmartCoordinatorPresentPresentation: OldSmartCoordinatorPresentation {
    var presentingViewController: UIViewController
    
    init(from currentPresentation: OldSmartCoordinatorPresentation) {
        presentingViewController = currentPresentation.presentingViewController
    }

    init(_ presentingNavigationController: UIViewController) {
        presentingViewController = presentingNavigationController
    }
    
    func run(presentedViewController: UIViewController) {
        guard let presentingViewController = presentingViewController as? UINavigationController else {
            print(OldSmartCoordinatorError.unsupportedPresentingViewController)
            return
        }

        if let presentedViewController = presentedViewController as? CustomPresentableViewController {
            presentingViewController.present(presentedViewController, interactiveDismissalType: .standard)
        } else {
            presentingViewController.present(presentedViewController, animated: true)
        }
    }
}

class OldSmartCoordinatorPushPresentation: OldSmartCoordinatorPresentation {
    var presentingViewController: UIViewController

    init(from currentPresentation: OldSmartCoordinatorPresentation) {
        presentingViewController = currentPresentation.presentingViewController
    }

    init(_ presentingNavigationController: UINavigationController) {
        presentingViewController = presentingNavigationController
    }

    func run(presentedViewController: UIViewController) {
        guard let presentingViewController = presentingViewController as? UINavigationController else {
            print(OldSmartCoordinatorError.unsupportedPresentingViewController)
            return
        }

        presentingViewController.pushViewController(presentedViewController, animated: true)
    }
}

class OldSmartCoordinatorBottomSheetPresentation: OldSmartCoordinatorPresentation {
    var presentingViewController: UIViewController

    private var subscriptions = [AnyCancellable]()
    private let transition: PanelTransition = .init()
    private let height: CGFloat

    init(from currentPresentation: OldSmartCoordinatorPresentation, height: CGFloat) {
        presentingViewController = currentPresentation.presentingViewController
        self.height = height
    }

    init(_ presentingViewController: UIViewController, height: CGFloat) {
        self.presentingViewController = presentingViewController
        self.height = height
    }

    func run(presentedViewController: UIViewController) {
        // Prepare
        transition.containerHeight = height
        transition.dimmClicked
            .sink(receiveValue: { _ in presentedViewController.dismiss(animated: true) })
            .store(in: &subscriptions)

        presentedViewController.view.layer.cornerRadius = 16
        presentedViewController.transitioningDelegate = transition
        presentedViewController.modalPresentationStyle = .custom

        // Presentation
        presentingViewController.present(presentedViewController, animated: true)
    }
}

class OldSmartCoordinator<T>: Coordinator<T> {
    let presentation: OldSmartCoordinatorPresentation

    let result = PassthroughSubject<T, Never>()

    init(presentation: OldSmartCoordinatorPresentation) {
        self.presentation = presentation
        super.init()
    }

    override final func start() -> Combine.AnyPublisher<T, Never> {
        let vc: UIViewController = build()

        if vc.onClose == nil {
            vc.onClose = { [weak self] in
                self?.result.send(completion: .finished)
            }
        }

        presentation.run(presentedViewController: vc)

        return result.prefix(1).eraseToAnyPublisher()
    }

    func build() -> UIViewController {
        fatalError("Overwrite `func build() -> UIViewController`")
    }
}
