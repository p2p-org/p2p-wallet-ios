import Combine
import SwiftUI
import SolanaSwift

final class SendInputFeePromptCoordinator: Coordinator<Wallet?> {
    private let parentController: UIViewController
    private let feeToken: Wallet
    private var subject = PassthroughSubject<Wallet?, Never>()

    init(parentController: UIViewController, feeToken: Wallet) {
        self.parentController = parentController
        self.feeToken = feeToken
    }

    override func start() -> AnyPublisher<Wallet?, Never> {
        let viewModel = SendInputFeePromptViewModel()
        let view = SendInputFeePromptView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        controller.modalPresentationStyle = .fullScreen

        parentController.present(controller, animated: true)

        viewModel.close
            .sink(receiveValue: { [weak self] in
                controller.dismiss(animated: true)
                self?.subject.send(completion: .finished)
            })
            .store(in: &subscriptions)

        viewModel.chooseToken
            .sink(receiveValue: { [weak self] in
                self?.openChooseToken(from: controller)
            })
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openChooseToken(from vc: UIViewController) {
        coordinate(to: ChooseWalletTokenCoordinator(strategy: .feeToken, chosenWallet: feeToken, parentController: vc))
            .sink { [weak self] value in
                vc.dismiss(animated: true)
                self?.subject.send(value)
            }
            .store(in: &subscriptions)
    }
}
