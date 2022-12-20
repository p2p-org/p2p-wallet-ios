import Combine
import SwiftUI
import SolanaSwift

final class SendInputFeePromptCoordinator: Coordinator<Wallet?> {
    private let parentController: UIViewController
    private let feeToken: Wallet
    private let availableFeeTokens: [Wallet]
    private var subject = PassthroughSubject<Wallet?, Never>()

    init(parentController: UIViewController, feeToken: Wallet, availableFeeTokens: [Wallet]) {
        self.parentController = parentController
        self.feeToken = feeToken
        self.availableFeeTokens = availableFeeTokens
    }

    override func start() -> AnyPublisher<Wallet?, Never> {
        let viewModel = SendInputFeePromptViewModel(feeToken: feeToken, availableFeeTokens: availableFeeTokens)
        let view = SendInputFeePromptView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        controller.modalPresentationStyle = .fullScreen

        parentController.present(controller, animated: true)

        viewModel.close
            .sink(receiveValue: { [weak self] in
                controller.dismiss(animated: true)
                if viewModel.feeToken.mintAddress != self?.feeToken.mintAddress {
                    self?.subject.send(viewModel.feeToken)
                }
                self?.subject.send(completion: .finished)
            })
            .store(in: &subscriptions)

        viewModel.chooseToken
            .sink(receiveValue: { [weak self] in
                self?.openChooseToken(from: controller, viewModel: viewModel)
            })
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openChooseToken(from vc: UIViewController, viewModel: SendInputFeePromptViewModel) {
        coordinate(to: ChooseWalletTokenCoordinator(strategy: .feeToken(tokens: availableFeeTokens), chosenWallet: feeToken, parentController: vc))
            .sink { value in
                guard let token = value else { return }
                viewModel.feeToken = token
            }
            .store(in: &subscriptions)
    }
}
