import Combine
import Send
import SolanaSwift
import SwiftUI
import Resolver

final class SendInputCoordinator: Coordinator<SendResult> {
    private let navigationController: UINavigationController
    private let recipient: Recipient
    private let preChosenWallet: Wallet?
    private let preChosenAmount: Double?
    private var subject = PassthroughSubject<SendResult, Never>()
    private let source: SendSource
    private let pushedWithoutRecipientSearchView: Bool
    private let allowSwitchingMainAmountType: Bool
    
    private let sendViaLinkSeed: String?

    init(
        recipient: Recipient,
        preChosenWallet: Wallet?,
        preChosenAmount: Double?,
        navigationController: UINavigationController,
        source: SendSource,
        pushedWithoutRecipientSearchView: Bool = false,
        allowSwitchingMainAmountType: Bool,
        sendViaLinkSeed: String? = nil
    ) {
        self.recipient = recipient
        self.preChosenWallet = preChosenWallet
        self.preChosenAmount = preChosenAmount
        self.navigationController = navigationController
        self.source = source
        self.pushedWithoutRecipientSearchView = pushedWithoutRecipientSearchView
        self.allowSwitchingMainAmountType = allowSwitchingMainAmountType
        self.sendViaLinkSeed = sendViaLinkSeed
    }

    override func start() -> AnyPublisher<SendResult, Never> {
        let viewModel = SendInputViewModel(recipient: recipient, preChosenWallet: preChosenWallet, preChosenAmount: preChosenAmount, source: source, allowSwitchingMainAmountType: allowSwitchingMainAmountType, sendViaLinkSeed: sendViaLinkSeed)
        let view = SendInputView(viewModel: viewModel)
        let controller = KeyboardAvoidingViewController(rootView: view, navigationBarVisibility: .visible)

        navigationController.pushViewController(controller, animated: true)
        setTitle(to: controller, isSendViaLink: sendViaLinkSeed != nil)

        controller.onClose = { [weak self] in
            self?.subject.send(.cancelled)
            self?.subject.send(completion: .finished)
        }

        controller.viewWillAppearPublisher.sink { _ in
            DispatchQueue.main.async {
                controller.navigationItem.largeTitleDisplayMode = .always
                controller.navigationController?.navigationBar.prefersLargeTitles = true
                controller.navigationController?.navigationBar.sizeToFit()
            }
        }.store(in: &subscriptions)

        viewModel.tokenViewModel.changeTokenPressed
            .sink { [weak self] in
                controller.hideKeyboard()
                self?.openChooseWalletToken(from: controller, viewModel: viewModel)
            }
            .store(in: &subscriptions)

        viewModel.openFeeInfo
            .sink { [weak self, weak viewModel] isFree in
                guard let self, let viewModel else { return }
                if viewModel.currentState.isSendingViaLink {
                    self.openFreeTransactionsDetail(
                        from: controller,
                        isSendingViaLink: true
                    )
                } else if viewModel.currentState.amountInToken == 0, isFree {
                    self.openFreeTransactionsDetail(
                        from: controller,
                        isSendingViaLink: false
                    )
                } else {
                    self.openFeeDetail(from: controller, viewModel: viewModel)
                }
            }
            .store(in: &subscriptions)

        viewModel.snackbar
            .sink { snackbar in
                snackbar.show(in: controller.navigationController?.view ?? controller.view)
            }
            .store(in: &subscriptions)

        viewModel.transaction
            .sink { [weak self, viewModel] model in
                if let seed = viewModel.stateMachine.currentState.sendViaLinkSeed {
                    let sendViaLinkDataService = Resolver.resolve(SendViaLinkDataService.self)
                    guard let link = sendViaLinkDataService.restoreURL(givenSeed: seed)?.absoluteString
                    else {
                        return
                    }
                    self?.subject.send(.sentViaLink(link: link, transaction: model))
                } else {
                    self?.subject.send(.sent(model))
                    self?.subject.send(completion: .finished)
                }
            }
            .store(in: &subscriptions)
        
        if pushedWithoutRecipientSearchView {
            Task { await viewModel.load() }
        }

        return subject.eraseToAnyPublisher()
    }

    private func setTitle(to vc: UIViewController, isSendViaLink: Bool) {
        if isSendViaLink {
            vc.title = L10n.sendViaOneTimeLink
        } else {
            switch recipient.category {
            case let .username(name, domain):
                vc.title = RecipientFormatter.username(name: name, domain: domain)
            default:
                vc.title = RecipientFormatter.format(destination: recipient.address)
            }
        }

        vc.navigationItem.largeTitleDisplayMode = .always
        vc.navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func openChooseWalletToken(from vc: UIViewController, viewModel: SendInputViewModel) {
        coordinate(to: ChooseSendItemCoordinator(
            strategy: .sendToken,
            chosenWallet: viewModel.sourceWallet,
            parentController: vc
        ))
        .sink { walletToken in
            if let walletToken = walletToken {
                viewModel.sourceWallet = walletToken
            }
            viewModel.openKeyboard()
        }
        .store(in: &subscriptions)
    }

    private func openFreeTransactionsDetail(
        from vc: UIViewController,
        isSendingViaLink: Bool
    ) {
        coordinate(to: SendInputFreeTransactionsDetailCoordinator(
            parentController: vc,
            isFreeTransactionsLimited: !isSendingViaLink
        ))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func openFeePropmt(from vc: UIViewController, viewModel: SendInputViewModel, feeWallets: [Wallet]) {
        guard let feeToken = viewModel.currentState.feeWallet else { return }
        coordinate(to: SendInputFeePromptCoordinator(
            parentController: vc,
            feeToken: feeToken,
            feeInToken: viewModel.currentState.feeInToken,
            availableFeeTokens: feeWallets
        ))
        .sink(receiveValue: { [weak viewModel] feeToken in
            guard let feeToken = feeToken else { return }
            viewModel?.changeFeeToken.send(feeToken)
        })
        .store(in: &subscriptions)
    }

    private func openFeeDetail(from vc: UIViewController, viewModel: SendInputViewModel) {
        coordinate(to: SendTransactionDetailsCoordinator(
            parentController: vc,
            sendInputViewModel: viewModel
        ))
        .sink { [weak self] result in
            switch result {
            case let .redirectToFeePrompt(tokens):
                self?.openFeePropmt(from: vc, viewModel: viewModel, feeWallets: tokens)
            }
        }
        .store(in: &subscriptions)
    }
}
