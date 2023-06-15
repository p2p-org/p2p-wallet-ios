import SwiftUI
import Combine
import Resolver

final class StrigaRegistrationHardErrorCoordinator: Coordinator<Void> {

    @Injected private var helpLauncher: HelpCenterLauncher
    private let navigationController: UINavigationController
    private let openBlank = PassthroughSubject<Void, Never>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = StrigaRegistrationHardErrorView(
            onAction: openBlank.send,
            onSupport: { [weak self] in self?.helpLauncher.launch() }
        )
        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.modalPresentationStyle = .fullScreen
        navigationController.present(vc, animated: true)

        return Publishers.Merge(
            vc.deallocatedPublisher(),
            openBlank
        )
        .prefix(1)
        .eraseToAnyPublisher()
    }
}
