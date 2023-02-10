import Combine
import SolanaSwift
import SwiftUI
import KeyAppUI

enum ChooseWalletTokenStrategy {
    case feeToken(tokens: [Wallet], feeInFiat: Double)
    case sendToken
}

final class ChooseWalletTokenCoordinator: Coordinator<Wallet?> {
    private let parentController: UIViewController
    private var subject = PassthroughSubject<Wallet?, Never>()
    private let strategy: ChooseWalletTokenStrategy
    private let chosenWallet: Wallet
    private let navigationController: UINavigationController

    init(strategy: ChooseWalletTokenStrategy, chosenWallet: Wallet, parentController: UIViewController) {
        self.strategy = strategy
        self.chosenWallet = chosenWallet
        self.parentController = parentController
        self.navigationController = UINavigationController()
    }

    override func start() -> AnyPublisher<Wallet?, Never> {
        let viewModel = ChooseWalletTokenViewModel(strategy: strategy, chosenToken: chosenWallet)
        let view = ChooseWalletTokenView(viewModel: viewModel)
        let controller = KeyboardAvoidingViewController(rootView: view, ignoresKeyboard: true)
        navigationController.setViewControllers([controller], animated: false)
        controller.title = viewModel.configureTitle(strategy: strategy)
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.MaterialIcon.close.image, style: .plain, target: self, action: #selector(closeButtonTapped))
        parentController.present(navigationController, animated: true)

        controller.onClose = { [weak self] in
            self?.subject.send(nil)
            self?.subject.send(completion: .finished)
        }

        viewModel.chooseTokenSubject
            .sink { [weak self] value in self?.close(wallet: value) }
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
