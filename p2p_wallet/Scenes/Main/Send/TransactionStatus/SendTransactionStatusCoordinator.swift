import Combine
import KeyAppUI
import SwiftUI

final class SendTransactionStatusCoordinator: Coordinator<Void> {
    private var bottomSheet: UIViewController?

    private let parentController: UIViewController
    private var subject = PassthroughSubject<Void, Never>()
    private let transaction: SendTransaction

    init(parentController: UIViewController, transaction: SendTransaction) {
        self.parentController = parentController
        self.transaction = transaction
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = SendTransactionStatusViewModel(transaction: transaction)
        let view = SendTransactionStatusView(viewModel: viewModel)
        let bottomSheet = BottomSheetController(rootView: view)
        parentController.present(bottomSheet, animated: true)
        self.bottomSheet = bottomSheet

        Publishers.Merge(
            viewModel.close,
            bottomSheet.deallocatedPublisher()
        )
            .sink { [weak self] in self?.finish() }
            .store(in: &subscriptions)

        return subject.prefix(1).eraseToAnyPublisher()
    }

    private func finish() {
        bottomSheet?.dismiss(animated: true)
        subject.send(completion: .finished)
    }

    private func style(nc: UINavigationController) {
        nc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nc.navigationBar.backgroundColor = Asset.Colors.snow.color
    }
}
