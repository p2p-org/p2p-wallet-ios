import Combine
import Send
import SolanaSwift
import SwiftUI

final class SendInputCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let recipient: Recipient
    private var subject = PassthroughSubject<Void, Never>()

    init(recipient: Recipient, navigationController: UINavigationController) {
        self.recipient = recipient
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = SendInputViewModel(recipient: recipient)
        let view = SendInputView(viewModel: viewModel)
        let controller = KeyboardAvoidingViewController(rootView: view)

        navigationController.pushViewController(controller, animated: true)
        setTitle(to: controller)

        viewModel.tokenViewModel.changeTokenPressed
            .sink { [weak self] in
                self?.openChooseWalletToken(from: controller, viewModel: viewModel)
            }
            .store(in: &subscriptions)

        viewModel.openFeeInfo
            .sink { [weak self] isFree in
                if isFree {
                    self?.openFreeTransactionsDetail(from: controller)
                } else {
                    self?.openFeePropmt(from: controller, viewModel: viewModel)
                }
            }
            .store(in: &subscriptions)

        viewModel.snackbar
            .sink { snackbar in
                snackbar.show(in: controller.navigationController?.view ?? controller.view)
            }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func setTitle(to vc: UIViewController) {
        switch recipient.category {
        case let .username(name, domain):
            vc.title = [name, domain].joined(separator: ".")
        default:
            vc.title = recipient.address
        }
        vc.title = recipient.address
        vc.navigationItem.largeTitleDisplayMode = .always
        vc.navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func openChooseWalletToken(from vc: UIViewController, viewModel: SendInputViewModel) {
        coordinate(to: ChooseWalletTokenCoordinator(strategy: .sendToken, chosenWallet: viewModel.currentToken, parentController: vc))
            .sink { walletToken in
                if let walletToken = walletToken {
                    viewModel.currentToken = walletToken
                }
            }
            .store(in: &subscriptions)
    }

    private func openFreeTransactionsDetail(from vc: UIViewController) {
        coordinate(to: SendInputFreeTransactionsDetailCoordinator(parentController: vc))
            .sink(receiveValue: { })
            .store(in: &subscriptions)
    }

    private func openFeePropmt(from vc: UIViewController, viewModel: SendInputViewModel) {
        coordinate(to: SendInputFeePromptCoordinator(parentController: vc, feeToken: viewModel.feeToken))
            .sink(receiveValue: { feeToken in
                if let feeToken = feeToken {
                    viewModel.feeToken = feeToken
                }
            })
            .store(in: &subscriptions)
    }
}
