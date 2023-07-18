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

        if let presentedViewController = presentedViewController as? CustomPresentableViewController {
            presentingViewController.present(presentedViewController, interactiveDismissalType: .standard)
        } else {
            presentingViewController.present(presentedViewController, animated: true)
        }
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

class SmartCoordinator<T>: Coordinator<T> {
    let presentation: SmartCoordinatorPresentation

    let result = PassthroughSubject<T, Never>()

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

    func pop(_ event: T) {
        ignoreOnCloseEvent = true

        if let navigation = presentation.presentingViewController as? UINavigationController {
            navigation.popViewController(animated: true) { [weak self] in
                self?.result.send(event)
            }
        }
    }

    override final func start() -> Combine.AnyPublisher<T, Never> {
        let vc: UIViewController = build()

        if vc.onClose == nil {
            vc.onClose = { [weak self] in
                guard self?.ignoreOnCloseEvent == false else { return }
                self?.result.send(completion: .finished)
            }
        }

        presentation.run(presentedViewController: vc)

//        vc.deallocatedPublisher()
//            .sink { [weak self] _ in
//                guard self?.ignoreOnCloseEvent == false else { return }
//                self?.result.send(completion: .finished)
//            }.store(in: &subscriptions)

        return result.prefix(1).eraseToAnyPublisher()
    }

    func build() -> UIViewController {
        fatalError("Overwrite `func build() -> UIViewController`")
    }
}
