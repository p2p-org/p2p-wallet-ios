import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeyAppStateMachine
import KeyAppUI
import Resolver
import Send

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

    let isTokenChoiceEnabled: Bool
    let allowSwitchingMainAmountType: Bool

    // MARK: - Properties

    let stateMachine: KeyAppStateMachine.StateMachine<SendInputDispatcher>

    var currentState: NSendInputState { stateMachine.currentState }

    @Published var status: Status = .initializing
    @Published var sourceWallet: SolanaAccount

    @Published var feeTitle = L10n.fees("")
    @Published var isFeeLoading: Bool = true
    @Published var loadingState: LoadableState = .loaded

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
    let transaction = PassthroughSubject<SendTransaction, Never>()

    init(
        recipient: Recipient,
        preChosenWallet _: SolanaAccount?,
        preChosenAmount _: Double?,
        flow _: SendFlow,
        allowSwitchingMainAmountType: Bool,
        sendViaLinkSeed _: String?
    ) {
        isTokenChoiceEnabled = false
        self.allowSwitchingMainAmountType = allowSwitchingMainAmountType

        let solanaAccountsService = Resolver.resolve(SolanaAccountsService.self)
        let initialAccount = solanaAccountsService.state.value.first
            ?? SolanaAccount(token: SolanaToken.nativeSolana)
        sourceWallet = initialAccount

        inputAmountViewModel = SendInputAmountViewModel(initialToken: initialAccount)

        stateMachine = .init(
            initialState: .initialising,
            dispatcher: SendInputDispatcher(
                sendProvider: Resolver.resolve(SendProvider.self)
            ),
            verbose: true
        )

        super.init()

        inputAmountViewModel.changeAmount
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] amount, _ in
                guard let self else { return }

                guard var input = currentState.input else {
                    return
                }

                input.amount = amount.inToken.toLamport(decimals: input.token.decimals)
                _ = await self.stateMachine.accept(action: .calculate(input: input))
            }
            .store(in: &subscriptions)

        stateMachine.statePublisher.removeDuplicates().sink { [weak self] state in
            guard let self else { return }
            switch state {
            case .initialising:
                isFeeLoading = true
            case let .calculating(input):
                isFeeLoading = true
            case let .ready(input, output):
                isFeeLoading = false
            case let .error(input, output, error):
                isFeeLoading = false
            }

            self.updateInputAmountView(state: state)
        }.store(in: &subscriptions)

        Task {
            await stateMachine.accept(action: .calculate(input: NSendInput(
                userWallet: initialAccount,
                recipient: recipient.address,
                token: initialAccount.token,
                amount: 10,
                feeSelectionMode: .auto(.sameToken),
                configuration: .init(swapMode: .exactOut, feePayer: .service)
            )))
        }
    }

    func initialize() {}

    func load() async {}

    func openKeyboard() {}
}

private extension NSendInputViewModel {
    func updateInputAmountView(state: NSendInputState) {
        switch state {
        case let .ready(input, output):
            let cryptoFormatter = CryptoFormatter()
            var title = L10n.send + cryptoFormatter.string(amount: input.tokenAmount)
            actionButtonData = SliderActionButtonData(isEnabled: true, title: title)
        default:
            var title = L10n.error
            actionButtonData = SliderActionButtonData(isEnabled: false, title: title)
        }
    }
}
