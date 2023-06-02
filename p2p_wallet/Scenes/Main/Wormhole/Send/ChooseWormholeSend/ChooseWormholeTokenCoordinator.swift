import Combine
import SolanaSwift
import SwiftUI
import KeyAppUI

final class ChooseWormholeTokenCoordinator: Coordinator<Wallet?> {
    private let subject = PassthroughSubject<Wallet?, Never>()
    private let chosenWallet: Wallet
    private let parentController: UIViewController
    private let navigationController: UINavigationController

    init(
        chosenWallet: Wallet,
        parentController: UIViewController
    ) {
        self.chosenWallet = chosenWallet
        self.parentController = parentController
        self.navigationController = UINavigationController()
    }

    override func start() -> AnyPublisher<Wallet?, Never> {
        let viewModel = ChooseItemViewModel(
            service: ChooseWormholeTokenService(),
            chosenItem: chosenWallet,
            isSearchEnabled: true
        )
        let view = ChooseItemView<TokenCellView>(viewModel: viewModel) { model in
            TokenCellView(item: .init(wallet: model.item as! Wallet), appearance: .other)
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
            .sink { [weak self] value in self?.close(wallet: value as? Wallet) }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func close(wallet: Wallet?) {
        navigationController.dismiss(animated: true)
        subject.send(wallet)
        subject.send(completion: .finished)
    }

    @objc private func closeButtonTapped() {
        self.close(wallet: nil)
    }
}
