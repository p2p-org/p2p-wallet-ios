import Combine
import UIKit

enum PincodeState {
    case create
    case confirm(pin: String)
}

final class PincodeCoordinator: Coordinator<Void> {
    private var subject = PassthroughSubject<Void, Never>()
    private weak var navigationController: UINavigationController?
    private let state: PincodeState

    init(navigationController: UINavigationController, state: PincodeState) {
        self.navigationController = navigationController
        self.state = state
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = PincodeViewModel(state: state)
        let viewController = PincodeViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)

        viewModel.$navigatableScene.sink { [weak self] scene in
            guard let self = self else { return }
            switch scene {
            case let .confirm(pin):
                self.openConfirm(pin: pin)
            case .openInfo:
                self.openInfo()
            case let .openMain(pin):
                break
            case .none:
                break
            }
        }.store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openConfirm(pin: String) {
        guard let nc = navigationController else { return }
        coordinate(to: PincodeCoordinator(navigationController: nc, state: .confirm(pin: pin)))
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)
    }

    private func openInfo() {}
}
