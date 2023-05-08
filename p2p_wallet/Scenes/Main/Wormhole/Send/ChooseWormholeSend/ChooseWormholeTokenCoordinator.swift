import Combine
import SolanaSwift
import SwiftUI
import KeyAppUI
import KeyAppKitCore

final class ChooseWormholeTokenCoordinator: Coordinator<SolanaAccount?> {
    private let subject = PassthroughSubject<SolanaAccount?, Never>()
    private let chosenWallet: SolanaAccount
    private let parentController: UIViewController
    private let navigationController: UINavigationController

    init(
        chosenWallet: SolanaAccount,
        parentController: UIViewController
    ) {
        self.chosenWallet = chosenWallet
        self.parentController = parentController
        self.navigationController = UINavigationController()
    }

    override func start() -> AnyPublisher<SolanaAccount?, Never> {
        let viewModel = ChooseItemViewModel(
            service: ChooseWormholeTokenService(),
            chosenToken: chosenWallet
        )
        let view = ChooseItemView<TokenCellView>(viewModel: viewModel) { model in
            TokenCellView(item: .init(solanaAccount: model.item as! SolanaAccount), appearance: .other)
        }
        let controller = KeyboardAvoidingViewController(rootView: view, ignoresKeyboard: true)
        navigationController.setViewControllers([controller], animated: false)
        controller.title = L10n.pickAToken
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.MaterialIcon.close.image, style: .plain, target: self, action: #selector(closeButtonTapped))
        parentController.present(navigationController, animated: true)

        controller.onClose = { [weak self] in
            self?.subject.send(nil)
            self?.subject.send(completion: .finished)
        }

        viewModel.chooseTokenSubject
            .sink { [weak self] value in self?.close(solanaAccount: value as? SolanaAccount) }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func close(solanaAccount: SolanaAccount?) {
        navigationController.dismiss(animated: true)
        subject.send(solanaAccount)
        subject.send(completion: .finished)
    }

    @objc private func closeButtonTapped() {
        self.close(solanaAccount: nil)
    }
}
