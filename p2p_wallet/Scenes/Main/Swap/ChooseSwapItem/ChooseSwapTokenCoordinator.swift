import Combine
import SolanaSwift
import SwiftUI

final class ChooseSwapTokenCoordinator: Coordinator<SwapToken?> {
    private let subject = PassthroughSubject<SwapToken?, Never>()
    private let chosenWallet: SwapToken
    private let navigationController: UINavigationController
    private let fromToken: Bool
    private let tokens: [SwapToken]
    private let title: String
    private var nonStrictTokenAlertVC: CustomPresentableViewController?

    init(
        chosenWallet: SwapToken,
        tokens: [SwapToken],
        navigationController: UINavigationController,
        fromToken: Bool,
        title: String? = nil
    ) {
        self.chosenWallet = chosenWallet
        self.tokens = tokens
        self.navigationController = navigationController
        self.fromToken = fromToken
        self.title = title ?? L10n.tokenYouPay
    }

    override func start() -> AnyPublisher<SwapToken?, Never> {
        let viewModel = ChooseItemViewModel(
            service: ChooseSwapTokenService(swapTokens: tokens, fromToken: fromToken),
            chosenToken: chosenWallet
        )
        let fromToken = fromToken
        let view = ChooseItemView<ChooseSwapTokenItemView>(viewModel: viewModel) { model in
            ChooseSwapTokenItemView(
                token: model.item as! SwapToken,
                chosen: model.isChosen,
                fromToken: fromToken
            )
        }
        let controller = KeyboardAvoidingViewController(rootView: view, ignoresKeyboard: true)
        controller.title = title
        navigationController.pushViewController(controller, animated: true)

        controller.onClose = { [weak self] in
            self?.subject.send(nil)
            self?.subject.send(completion: .finished)
        }

        viewModel.chooseTokenSubject
            .sink { [weak self] value in
                self?.openNonStrictTokenConfirmationIfNeededOrClose(
                    token: value as? SwapToken
                )
            }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    // MARK: - Navigation

    private func openNonStrictTokenConfirmationIfNeededOrClose(
        token: SwapToken?
    ) {
        if token?.token.tags.map(\.name).contains("unknown") == true {
            nonStrictTokenAlertVC = UIBottomSheetHostingController(
                rootView: NonStrictTokenConfirmationView(
                    token: token
                ) {
                    [weak self] in
                    self?.nonStrictTokenAlertVC?.dismiss(animated: true) { [weak self] in
                        self?.close(token: token)
                    }
                },
                shouldIgnoresKeyboard: true
            )
            nonStrictTokenAlertVC!.view.layer.cornerRadius = 20

            // present bottom sheet
            navigationController.present(nonStrictTokenAlertVC!, interactiveDismissalType: .standard)
        } else {
            close(token: token)
        }
    }

    private func close(token: SwapToken?) {
        navigationController.popViewController(animated: true, completion: {})
        subject.send(token)
        subject.send(completion: .finished)
    }

    @objc private func closeButtonTapped() {
        close(token: nil)
    }
}
