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
        let fromViewModel = SwapInputViewModel(stateMachine: viewModel.stateMachine, isFromToken: true)
        let toViewModel = SwapInputViewModel(stateMachine: viewModel.stateMachine, isFromToken: false)
        let view = SwapView(viewModel: viewModel, fromViewModel: fromViewModel, toViewModel: toViewModel)
        let controller = KeyboardAvoidingViewController(rootView: view)
        navigationController.pushViewController(controller, animated: true)
        style(controller: controller)

        fromViewModel.changeTokenPressed
            .sink { [weak viewModel, weak self] in
                guard let self, let viewModel else { return }
                self.openChooseToken(viewModel: viewModel, fromToken: true)
            }
            .store(in: &subscriptions)
        viewModel.toTokenViewModel.changeTokenPressed
            .sink { [weak viewModel, weak self] in
                guard let self, let viewModel else { return }
                self.openChooseToken(viewModel: viewModel, fromToken: false)
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
    
    private func openChooseToken(viewModel: SwapViewModel, fromToken: Bool) {
        coordinate(to: ChooseSwapTokenCoordinator(
            chosenWallet: fromToken ? viewModel.fromToken : viewModel.toToken,
            tokens: fromToken ? viewModel.tokens : viewModel.toTokens,
            navigationController: navigationController
        ))
        .compactMap { $0 }
        .sink {
            if fromToken {
                viewModel.fromToken = $0
            } else {
                viewModel.toToken = $0
            }
        }
        .store(in: &subscriptions)
    }

private func openChooseFromToken(viewModel: SwapViewModel) {
        self.coordinate(to: ChooseSwapTokenCoordinator(
            chosenWallet: viewModel.currentState.fromToken,
            tokens: viewModel.currentState.swapTokens,
            navigationController: self.navigationController)
        )
        .sink { result in
            if let result {
                viewModel.changeFromToken.send(result)
            }
        }
        .store(in: &self.subscriptions)

    }
}
