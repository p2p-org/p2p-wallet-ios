import Combine
import NameService
import SwiftUI
import UIKit

enum NavigationOption {
    case onboarding(window: UIWindow)
    case settings(parent: UINavigationController)
}

final class CreateUsernameCoordinator: Coordinator<Void> {
    private let navigationOption: NavigationOption
    private var subject = PassthroughSubject<Void, Never>()
    private weak var viewModel: CreateUsernameViewModel?

    init(navigationOption: NavigationOption) {
        self.navigationOption = navigationOption
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = CreateUsernameViewModel(parameters: parameters())
        let view = CreateUsernameView(viewModel: viewModel)
        let controller = KeyboardAvoidingViewController(rootView: view)
        self.viewModel = viewModel

        switch navigationOption {
        case let .onboarding(window):
            let navigationController = UINavigationController()
            navigationController.setViewControllers([controller], animated: true)
            window.animate(newRootViewController: navigationController)
            addSkipButtonIfNeeded(to: controller)

        case let .settings(parent):
            controller.hidesBottomBarWhenPushed = true
            parent.pushViewController(controller, animated: true)
        }

        Publishers.Merge(viewModel.skip, viewModel.close)
            .sink { [unowned self] in
                self.subject.send(())
                self.subject.send(completion: .finished)
            }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }
}

private extension CreateUsernameCoordinator {
    func parameters() -> CreateUsernameParameters {
        switch navigationOption {
        case .onboarding:
            return .init(backgroundColor: .lime, buttonStyle: .primary)
        case .settings:
            return .init(backgroundColor: .rain, buttonStyle: .primaryWhite)
        }
    }

    func addSkipButtonIfNeeded(to vc: UIViewController) {
        guard available(.onboardingUsernameButtonSkipEnabled) else { return }
        // We have to add button here because of KeyboardAvoidingViewController. SwiftUI view doesn't see navigationItem
        // with custom UIViewController wrapper
        let button = UIBarButtonItem(
            title: L10n.skip.uppercaseFirst,
            style: .plain,
            target: self,
            action: #selector(skip)
        )
        button.tintColor = .init(resource: .night)
        vc.navigationItem.rightBarButtonItem = button
    }

    @objc func skip() {
        viewModel?.skip.send(())
    }
}
