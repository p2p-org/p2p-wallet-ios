import Combine
import SwiftUI
import KeyAppUI

final class NewSwapCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private var result = PassthroughSubject<Void, Never>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = SwapViewModel()
        let view = SwapView(viewModel: viewModel)
        let controller = KeyboardAvoidingViewController(rootView: view)
        navigationController.pushViewController(controller, animated: true)
        style(controller: controller)

        viewModel.fromTokenViewModel.changeTokenPressed
            .sink { [weak viewModel, weak self] in
                guard let self, let viewModel else { return }
                self.openChooseFromToken(viewModel: viewModel)
            }
            .store(in: &subscriptions)

        return result.prefix(1).eraseToAnyPublisher()
    }

    func style(controller: UIViewController) {
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.backgroundColor = Asset.Colors.smoke.color
        controller.title = L10n.swap
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(image: .receipt, style: .plain, target: self, action: #selector(receiptButtonPressed))
    }

    @objc private func receiptButtonPressed() {
        
    }

    private func openChooseFromToken(viewModel: SwapViewModel) {
        self.coordinate(to: ChooseSwapTokenCoordinator(chosenWallet: viewModel.fromToken, tokens: viewModel.tokens, navigationController: self.navigationController))
            .sink { result in
                if let result {
                    viewModel.fromToken = result
                }
            }
            .store(in: &self.subscriptions)

    }
}
