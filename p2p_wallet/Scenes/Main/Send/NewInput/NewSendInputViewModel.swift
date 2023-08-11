import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeyAppStateMachine
import KeyAppUI
import Resolver
import Send

public extension Publisher where Output: Equatable, Failure == Never {
    func aggregate<Root: AnyObject, TransformedOutput: Equatable>(
        on root: Root,
        to keyPath: ReferenceWritableKeyPath<Root, TransformedOutput>,
        transform: @escaping (Output) -> TransformedOutput
    ) -> AnyCancellable {
        map(transform)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak root] in
                root?[keyPath: keyPath] = $0
            }
    }
}

final class NSendInputViewModel: BaseViewModel, ObservableObject {
    // MARK: - Type

    enum Status {
        case initializing
        case initializingFailed
        case ready
    }

    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Subview models

    let inputAmountViewModel: SendInputAmountViewModel

    // MARK: - Configuration

    let allowSwitchAccount: Bool

    // MARK: - Properties

    let stateMachine: KeyAppStateMachine.StateMachine<SendInputDispatcher>

    @Published var currentState: NSendInputState = .initialising

    @Published var loadingState: LoadableState = .loaded
    @Published var fee: SendInputFeeData = .init(loading: true, title: L10n.fees(""))

    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false
    @Published var showFinished = false

    private var wasMaxWarningToastShown: Bool = false

    // MARK: - Actions

    let changeTokenPressed = PassthroughSubject<Void, Never>()
    let feeInfoPressed = PassthroughSubject<Void, Never>()
    let openFeeInfo = PassthroughSubject<Bool, Never>()
    let changeFeeToken = PassthroughSubject<SolanaAccount, Never>()
    let snackBar = PassthroughSubject<SnackBar, Never>()
    let transaction = PassthroughSubject<PendingTransaction, Never>()

    /// Initializing view model
    /// - Parameters:
    ///   - recipient: The destination recipient information
    ///   - account: The account that will be withdrawn
    ///   - allowSwitchAccount: Allow to select another account for withdrawing
    ///   - solanaAccountsService: Solana account service
    init(
        recipient: Recipient,
        account: SolanaAccount?,
        allowSwitchAccount: Bool,
        solanaAccountsService: SolanaAccountsService = Resolver.resolve()
    ) {
        self.allowSwitchAccount = allowSwitchAccount

        let account = account
            ?? solanaAccountsService.state.value.first
            ?? solanaAccountsService.nativeAccount

        inputAmountViewModel = SendInputAmountViewModel(initialToken: account)
        inputAmountViewModel.token = account

        stateMachine = .init(
            initialState: .initialising,
            dispatcher: SendInputDispatcher(
                sendProvider: Resolver.resolve(SendProvider.self)
            ),
            verbose: true
        )

        super.init()

        $currentState.sink { state in
            print("STATTE", state)
        }.store(in: &subscriptions)

        $isSliderOn
            .sinkAsync(receiveValue: { [weak self] isSliderOn in
                guard let self else { return }
                if isSliderOn {
                    await self.send()
                    self.isSliderOn = false
                    self.showFinished = false
                }
            })
            .store(in: &subscriptions)

        inputAmountViewModel.changeAmount
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] amount, _ in
                guard let self else { return }

                guard var input = currentState.input else {
                    return
                }

                input.amount = amount.inToken.toLamport(decimals: input.account.token.decimals)
                _ = await self.stateMachine.accept(action: .calculate(input: input))
            }
            .store(in: &subscriptions)

        // Bind action button
        stateMachine
            .statePublisher
            .assignWeak(to: \.currentState, on: self)
            .store(in: &subscriptions)

        stateMachine
            .statePublisher
            .aggregate(on: self, to: \.actionButtonData, transform: SendInputSliderAggregator().transform)
            .store(in: &subscriptions)

        stateMachine
            .statePublisher
            .aggregate(on: self, to: \.fee, transform: SendInputFeeDataAggregator().transform)
            .store(in: &subscriptions)

        Task {
            let walletManager: UserWalletManager = Resolver.resolve()

            await stateMachine.accept(action: .calculate(input: NSendInput(
                owner: walletManager.wallet?.account.publicKey.base58EncodedString ?? "",
                account: account,
                recipient: recipient.address,
                amount: 0,
                feeSelectionMode: .auto(.sameToken),
                configuration: .init(swapMode: .exactOut, feePayer: .service)
            )))
        }
    }

    func initialize() {}

    func load() async {}

    func changeAccount(account: SolanaAccount) {
        DispatchQueue.main.async {
            self.inputAmountViewModel.token = account
        }

        Task {
            if var currentInput = currentState.input {
                currentInput.account = account
                await stateMachine.accept(action: .calculate(input: currentInput))
            }
        }
    }

    func openKeyboard() {}

    func send() async {
        guard case let .ready(input, output) = currentState else {
            return
        }

        await MainActor.run {
            let transaction = SimpleSendTransaction(input: input, output: output)

            let handler: TransactionHandler = Resolver.resolve()
            let index = handler.sendTransaction(transaction)
            let pending = handler.transactionsSubject.value[index]

            self.transaction.send(pending)
        }
    }
}

extension NSendInputViewModel {
    var status: Status {
        switch currentState {
        case .initialising:
            return .initializing
        default:
            return .ready
        }
    }
}

private extension NSendInputViewModel {}
