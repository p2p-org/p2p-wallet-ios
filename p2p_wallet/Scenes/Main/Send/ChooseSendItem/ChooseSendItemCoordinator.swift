import Combine
import SolanaSwift
import SwiftUI
import KeyAppUI
import KeyAppKitCore

enum ChooseWalletTokenStrategy {
    case feeToken(tokens: [SolanaAccount], feeInFiat: Double)
    case sendToken
}

final class ChooseSendItemCoordinator: Coordinator<SolanaAccount?> {
    private let parentController: UIViewController
    private var subject = PassthroughSubject<SolanaAccount?, Never>()
    private let strategy: ChooseWalletTokenStrategy
    private let chosenWallet: SolanaAccount
    private let navigationController: UINavigationController

    init(strategy: ChooseWalletTokenStrategy, chosenWallet: SolanaAccount, parentController: UIViewController) {
        self.strategy = strategy
        self.chosenWallet = chosenWallet
        self.parentController = parentController
        self.navigationController = UINavigationController()
    }

    override func start() -> AnyPublisher<SolanaAccount?, Never> {
        let viewModel = ChooseItemViewModel(
            service: buildService(strategy: strategy),
            chosenToken: chosenWallet
        )
        let view = ChooseItemView<TokenCellView>(viewModel: viewModel) { model in
            TokenCellView(item: .init(wallet: model.item as! SolanaAccount), appearance: .other)
        }
        let controller = KeyboardAvoidingViewController(rootView: view, ignoresKeyboard: true)
        navigationController.setViewControllers([controller], animated: false)
        configureTitle(strategy: strategy, vc: controller)
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.MaterialIcon.close.image, style: .plain, target: self, action: #selector(closeButtonTapped))
        parentController.present(navigationController, animated: true)

        controller.onClose = { [weak self] in
            self?.subject.send(nil)
            self?.subject.send(completion: .finished)
        }

        viewModel.chooseTokenSubject
            .sink { [weak self] value in self?.close(wallet: value as? SolanaAccount) }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func close(wallet: SolanaAccount?) {
        navigationController.dismiss(animated: true)
        subject.send(wallet)
        subject.send(completion: .finished)
    }

    @objc private func closeButtonTapped() {
        self.close(wallet: nil)
    }

    private func configureTitle(strategy: ChooseWalletTokenStrategy, vc: UIViewController) {
        switch strategy {
        case let .feeToken(_, feeInFiat):
            vc.title = L10n.payTheFeeWith("~\(feeInFiat.fiatAmountFormattedString(roundingMode: .down))")
        case .sendToken:
            vc.title = L10n.pickAToken
        }
    }

    private func buildService(strategy: ChooseWalletTokenStrategy) -> ChooseItemService {
        switch strategy {
        case .feeToken(let tokens, _):
            return ChooseSendFeeTokenService(tokens: tokens)
        case .sendToken:
            return ChooseSendTokenService()
        }
    }
}
