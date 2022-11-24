import Combine
import SolanaSwift
import SwiftUI

final class ChooseWalletTokenCoordinator: Coordinator<Wallet?> {
    private let parentController: UIViewController
    private var subject = PassthroughSubject<Wallet?, Never>()
    private let chosenWallet: Wallet

    init(chosenWallet: Wallet, parentController: UIViewController) {
        self.chosenWallet = chosenWallet
        self.parentController = parentController
    }

    override func start() -> AnyPublisher<Wallet?, Never> {
        let viewModel = ChooseWalletTokenViewModel(chosenToken: chosenWallet)
        let view = ChooseWalletTokenView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        parentController.present(controller, animated: true)

        viewModel.close
            .sink { [weak self] in self?.close(vc: controller, wallet: nil) }
            .store(in: &subscriptions)

        viewModel.chooseTokenSubject
            .sink { [weak self] value in self?.close(vc: controller, wallet: value) }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func close(vc: UIViewController, wallet: Wallet?) {
        vc.dismiss(animated: true)
        subject.send(wallet)
        subject.send(completion: .finished)
    }
}
