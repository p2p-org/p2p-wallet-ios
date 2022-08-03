import Combine
import KeyAppUI
import SwiftUI
import UIKit

final class ProtectionLevelCoordinator: Coordinator<Void> {
    private weak var navigationController: UINavigationController?
    private weak var vc: UIViewController?
    private var subject = PassthroughSubject<Void, Never>()

    // MARK: - Initializer

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = ProtectionLevelViewModel()
        let view = ProtectionLevelView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        vc = viewController

        navigationController?.pushViewController(viewController, animated: true)
        addRightButton()

        viewModel.$navigatableScene.sink { [weak self] scene in
            guard let self = self else { return }
            switch scene {
            case .pin:
                self.openPin()
            case .none:
                break
            }
        }.store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openPin() {
        guard let nc = navigationController else { return }
        coordinate(to: PincodeCoordinator(navigationController: nc, state: .create))
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)
    }

    @objc private func openInfo() {}

    private func addRightButton() {
        let infoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        infoButton.addTarget(self, action: #selector(openInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        vc?.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }
}
