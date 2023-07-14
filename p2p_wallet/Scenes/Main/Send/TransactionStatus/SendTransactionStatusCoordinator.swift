import Combine
import SwiftUI

final class SendTransactionStatusCoordinator: Coordinator<Void> {
    private var transition: PanelTransition?

    private let navigationController: UINavigationController
    private let container: UIViewController

    private let parentController: UIViewController
    private var subject = PassthroughSubject<Void, Never>()
    private let transaction: SendTransaction

    init(parentController: UIViewController, transaction: SendTransaction) {
        self.parentController = parentController
        self.transaction = transaction
        navigationController = UINavigationController()
        container = UIViewController()
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = SendTransactionStatusViewModel(transaction: transaction)
        let view = SendTransactionStatusView(viewModel: viewModel)

        viewModel.close
            .sink { [weak self] in self?.finish() }
            .store(in: &subscriptions)

        transition = PanelTransition()
        transition?.containerHeight = 624
        transition?.dimmClicked
            .sink { [weak self] in self?.finish() }
            .store(in: &subscriptions)

        let viewController = UIHostingController(rootView: view)
        navigationController.setViewControllers([viewController], animated: true)
        style(nc: navigationController)
        wrap(for: navigationController)

        container.transitioningDelegate = transition
        container.modalPresentationStyle = .custom
        container.view.layer.cornerRadius = 20
        container.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        parentController.present(container, animated: true)

        viewModel.openDetails
            .sink { [weak self] params in
                self?.openDetails(params: params)
            }
            .store(in: &subscriptions)

        return subject.prefix(1).eraseToAnyPublisher()
    }

    private func finish() {
        container.dismiss(animated: true)
        subject.send(completion: .finished)
    }

    private func openDetails(params: SendTransactionStatusDetailsParameters) {
        coordinate(to: SendTransactionStatusDetailsCoordinator(
            navigationController: navigationController,
            params: params
        ))
        .sink { [weak self] result in
            switch result {
            case .close:
                self?.finish()
            }
        }
        .store(in: &subscriptions)
    }

    private func style(nc: UINavigationController) {
        nc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nc.navigationBar.backgroundColor = .init(resource: .snow)
    }

    private func wrap(for navigationController: UINavigationController) {
        let closeView = UIView()
        closeView.backgroundColor = .init(resource: .rain)
        closeView.layer.cornerRadius = 2
        container.view.addSubview(closeView)
        container.view.backgroundColor = .init(resource: .snow)
        closeView.autoSetDimensions(to: .init(width: 31, height: 4))
        closeView.autoPinEdge(toSuperviewEdge: .top, withInset: 6)
        NSLayoutConstraint.activate([closeView.centerXAnchor.constraint(equalTo: container.view.centerXAnchor)])

        container.view.addSubview(navigationController.view)
        navigationController.view.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
        navigationController.view.autoPinEdge(toSuperviewEdge: .bottom)
        navigationController.view.autoPinEdge(toSuperviewEdge: .leading)
        navigationController.view.autoPinEdge(toSuperviewEdge: .trailing)
        navigationController.didMove(toParent: container)
    }
}
