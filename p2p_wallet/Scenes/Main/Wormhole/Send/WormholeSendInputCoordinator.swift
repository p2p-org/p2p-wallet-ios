import Foundation
import KeyAppKitCore
import Send
import SolanaSwift
import SwiftUI

enum WormholeSendInputCoordinatorResult {
    case transaction(WormholeSendUserAction)
}

final class WormholeSendInputCoordinator: SmartCoordinator<WormholeSendInputCoordinatorResult> {
    private let recipient: Recipient
    private let preChosenWallet: SolanaAccount?

    init(recipient: Recipient, from: UINavigationController, preChosenWallet: SolanaAccount? = nil) {
        self.recipient = recipient
        self.preChosenWallet = preChosenWallet
        super.init(presentation: SmartCoordinatorPushPresentation(from))
    }

    override func build() -> UIViewController {
        let viewModel = WormholeSendInputViewModel(
            recipient: recipient,
            preChosenWallet: preChosenWallet
        )
        let view = WormholeSendInputView(viewModel: viewModel)
        let vc = UIHostingController(rootView: view)

        viewModel.action
            .sink { [weak self] action in
                switch action {
                case .openPickAccount:
                    self?.openChooseWormholeToken(from: vc, viewModel: viewModel)
                case .openFees:
                    self?.openFees(stateMachine: viewModel.stateMachine)
                case let .send(trx):
                    self?.pop(.transaction(trx))
                }
            }
            .store(in: &subscriptions)

        return vc
    }

    private func openFees(stateMachine: WormholeSendInputStateMachine) {
        coordinate(to: WormholeSendFeesCoordinator(stateMachine: stateMachine,
                                                   presentedVC: presentation.presentingViewController))
            .sink { _ in }
            .store(in: &subscriptions)
    }

    private func openChooseWormholeToken(from vc: UIViewController, viewModel: WormholeSendInputViewModel) {
        coordinate(to: ChooseWormholeTokenCoordinator(
            chosenWallet: viewModel.adapter.inputAccount ?? .classicSPLTokenAccount(
                address: "",
                lamports: 0,
                token: .eth
            ),
            parentController: vc
        ))
        .sink { walletToken in
            if let walletToken = walletToken {
                viewModel.selectSolanaAccount(wallet: walletToken)
            }
        }
        .store(in: &subscriptions)
    }
}
