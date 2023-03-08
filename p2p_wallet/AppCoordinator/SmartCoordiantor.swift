// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import UIKit

enum SmartCoordinatorError {
    case unsupportedPresentingViewController
}

protocol SmartCoordinatorPresentation {
    var presentingViewController: UIViewController { get }

    func run(presentedViewController: UIViewController)
}

class SmartCoordinatorPresentPresentation: SmartCoordinatorPresentation {
    var presentingViewController: UIViewController

    init(from currentPresentation: SmartCoordinatorPresentation) {
        presentingViewController = currentPresentation.presentingViewController
    }

    init(_ presentingNavigationController: UIViewController) {
        presentingViewController = presentingNavigationController
    }

    func run(presentedViewController: UIViewController) {
        guard let presentingViewController = presentingViewController as? UINavigationController else {
            print(SmartCoordinatorError.unsupportedPresentingViewController)
            return
        }

        presentingViewController.present(presentedViewController, animated: true)
    }
}

class SmartCoordinatorPushPresentation: SmartCoordinatorPresentation {
    var presentingViewController: UIViewController

    init(from currentPresentation: SmartCoordinatorPresentation) {
        presentingViewController = currentPresentation.presentingViewController
    }

    init(_ presentingNavigationController: UINavigationController) {
        presentingViewController = presentingNavigationController
    }

    func run(presentedViewController: UIViewController) {
        guard let presentingViewController = presentingViewController as? UINavigationController else {
            print(SmartCoordinatorError.unsupportedPresentingViewController)
            return
        }

        presentingViewController.pushViewController(presentedViewController, animated: true)
    }
}

class SmartCoordinatorBottomSheetPresentation: SmartCoordinatorPresentation {
    var presentingViewController: UIViewController

    private var subscriptions = [AnyCancellable]()
    private let transition: PanelTransition = .init()
    private let height: CGFloat

    init(from currentPresentation: SmartCoordinatorPresentation, height: CGFloat) {
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

class SmartCoordinator<T>: Coordinator<T> {
    let presentation: SmartCoordinatorPresentation

    let result: PassthroughSubject<T, Never> = .init()

    private var ignoreOnCloseEvent: Bool = false

    init(presentation: SmartCoordinatorPresentation) {
        self.presentation = presentation
        super.init()
    }

    func dismiss(_ event: T) {
        ignoreOnCloseEvent = true
        presentation.presentingViewController.dismiss(animated: true) { [weak self] in
            self?.result.send(event)
        }
    }

    override final func start() -> Combine.AnyPublisher<T, Never> {
        let vc: UIViewController = build()

        vc.onClose = { [weak self] in
            guard self?.ignoreOnCloseEvent == false else { return }
            self?.result.send(completion: .finished)
        }

        presentation.run(presentedViewController: vc)

//        vc.deallocatedPublisher()
//            .sink { [weak self] _ in
//                self?.result.send(completion: .finished)
//            }.store(in: &subscriptions)

        return result.prefix(1).eraseToAnyPublisher()
    }

    func build() -> UIViewController {
        fatalError("Overwrite `func build() -> UIViewController`")
    }
}
