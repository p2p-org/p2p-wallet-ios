import Combine
import SolanaSwift

final class RecipientSearchCoordinator: Coordinator<SendResult> {
    private let rootViewController: UINavigationController
    private let result = PassthroughSubject<SendResult, Never>()
    private let source: SendSource
    private let allowSwitchingMainAmountType: Bool
    private let preChosenWallet: Wallet?

    init(
        rootViewController: UINavigationController,
        preChosenWallet: Wallet?,
        source: SendSource = .none,
        allowSwitchingMainAmountType: Bool
    ) {
        self.rootViewController = rootViewController
        self.source = source
        self.allowSwitchingMainAmountType = allowSwitchingMainAmountType
        self.preChosenWallet = preChosenWallet
        super.init()
    }

    override func start() -> AnyPublisher<SendResult, Never> {
        // Setup view
        let vm = RecipientSearchViewModel(preChosenWallet: preChosenWallet, source: source)
        vm.coordinator.selectRecipientPublisher
            .flatMap { [unowned self] in
                self.coordinate(to: SendInputCoordinator(
                    parameters: SendInputParameters(
                        source: source,
                        recipient: $0,
                        preChosenWallet: preChosenWallet,
                        preChosenAmount: nil,
                        pushedWithoutRecipientSearchView: false,
                        allowSwitchingMainAmountType: allowSwitchingMainAmountType
                    ),
                    navigationController: rootViewController
                ))
            }
            .sink { [weak self] result in
                switch result {
                case let .sent(transaction):
                    self?.result.send(.sent(transaction))
                case .cancelled:
                    break
                }
            }
            .store(in: &subscriptions)

        vm.coordinator.scanQRPublisher
            .flatMap { [unowned self] in
                self.coordinate(to: ScanQrCoordinator(navigationController: rootViewController))
            }
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak vm] result in
                vm?.searchQR(query: result, autoSelectTheOnlyOneResultMode: .enabled(delay: 0))
            }).store(in: &subscriptions)
        
        Task {
            await vm.load()
        }

        let view = RecipientSearchView(viewModel: vm)
        let vc = KeyboardAvoidingViewController(rootView: view, navigationBarVisibility: .visible)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.navigationItem.setTitle(L10n.chooseARecipient, subtitle: L10n.solanaNetwork)
        vc.hidesBottomBarWhenPushed = rootViewController.tabBarController != nil
        // Push strategy
        rootViewController.pushViewController(vc, animated: true)

        vc.onClose = { [weak self] in
            self?.result.send(.cancelled)
        }

        return result.prefix(1).eraseToAnyPublisher()
    }
}
