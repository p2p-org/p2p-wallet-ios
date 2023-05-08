import Combine
import SwiftUI
import SolanaSwift
import KeyAppKitCore

final class SendInputFeePromptCoordinator: Coordinator<SolanaAccount?> {
    private let parentController: UIViewController
    private let feeToken: SolanaAccount
    private let feeInToken: FeeAmount
    private let availableFeeTokens: [SolanaAccount]
    private var subject = PassthroughSubject<SolanaAccount?, Never>()

    init(parentController: UIViewController, feeToken: SolanaAccount, feeInToken: FeeAmount, availableFeeTokens: [SolanaAccount]) {
        self.parentController = parentController
        self.feeToken = feeToken
        self.feeInToken = feeInToken
        self.availableFeeTokens = availableFeeTokens
    }

    override func start() -> AnyPublisher<SolanaAccount?, Never> {
        let viewModel = SendInputFeePromptViewModel(feeToken: feeToken, feeInToken: feeInToken, availableFeeTokens: availableFeeTokens)
        let view = SendInputFeePromptView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        controller.modalPresentationStyle = .fullScreen

        parentController.present(controller, animated: true)

        viewModel.close
            .sink(receiveValue: { [weak self, weak controller] in
                controller?.dismiss(animated: true)
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
        coordinate(to: ChooseSendItemCoordinator(
            strategy: .feeToken(tokens: availableFeeTokens, feeInFiat: viewModel.feeInFiat),
            chosenWallet: feeToken,
            parentController: vc)
        )
        .sink { [weak self] value in
            guard let token = value else { return }
            viewModel.feeToken = token
            self?.subject.send(viewModel.feeToken)
            self?.subject.send(completion: .finished)
            vc.dismiss(animated: true)
        }
        .store(in: &subscriptions)
    }
}
