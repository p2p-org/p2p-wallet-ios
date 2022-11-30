import Combine
import SwiftUI
import SolanaSwift

final class SendInputFeePromptCoordinator: Coordinator<Wallet?> {
    private let parentController: UIViewController
    private let currentToken: Wallet
    private let feeToken: Wallet
    private let feeInSOL: FeeAmount
    private var subject = PassthroughSubject<Wallet?, Never>()

    init(parentController: UIViewController, currentToken: Wallet, feeToken: Wallet, feeInSOL: FeeAmount) {
        self.parentController = parentController
        self.currentToken = currentToken
        self.feeToken = feeToken
        self.feeInSOL = feeInSOL
    }

    override func start() -> AnyPublisher<Wallet?, Never> {
        let viewModel = SendInputFeePromptViewModel(currentToken: currentToken.token, feeToken: feeToken.token)
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
        coordinate(to: ChooseWalletTokenCoordinator(strategy: .feeToken(feeInSOL: feeInSOL), chosenWallet: feeToken, parentController: vc))
            .sink { [weak self] value in
                vc.dismiss(animated: true)
                self?.subject.send(value)
            }
            .store(in: &subscriptions)
    }
}
