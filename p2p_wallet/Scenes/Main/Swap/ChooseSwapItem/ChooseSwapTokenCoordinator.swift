import Combine
import SolanaSwift
import SwiftUI
import KeyAppUI

final class ChooseSwapTokenCoordinator: Coordinator<SwapToken?> {
    private var subject = PassthroughSubject<SwapToken?, Never>()
    private let chosenWallet: SwapToken
    private let navigationController: UINavigationController
    private let tokens: [SwapToken]

    init(chosenWallet: SwapToken, tokens: [SwapToken], navigationController: UINavigationController) {
        self.chosenWallet = chosenWallet
        self.tokens = tokens
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<SwapToken?, Never> {
        let viewModel = ChooseItemViewModel(
            service: ChooseSwapTokenService(swapTokens: tokens),
            chosenToken: chosenWallet
        )
        let view = ChooseItemView<ChooseSwapTokenItemView>(viewModel: viewModel) { model in
            ChooseSwapTokenItemView(token: model.item as! SwapToken, isChosen: model.isChosen)
        }
        let controller = KeyboardAvoidingViewController(rootView: view, ignoresKeyboard: true)
        controller.title = L10n.theTokenYouPay
        navigationController.pushViewController(controller, animated: true)

        controller.onClose = { [weak self] in
            self?.subject.send(nil)
            self?.subject.send(completion: .finished)
        }

        viewModel.chooseTokenSubject
            .sink { [weak self] value in self?.close(token: value as? SwapToken) }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func close(token: SwapToken?) {
        navigationController.popViewController(animated: true, completion: {})
        subject.send(token)
        subject.send(completion: .finished)
    }

    @objc private func closeButtonTapped() {
        self.close(token: nil)
    }
}
