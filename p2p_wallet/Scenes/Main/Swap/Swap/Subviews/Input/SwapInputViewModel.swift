import Combine
import Resolver
import KeyAppUI

final class SwapInputViewModel: BaseViewModel, ObservableObject {

    let allButtonPressed = PassthroughSubject<Void, Never>()
    let amountFieldTap = PassthroughSubject<Void, Never>()
    let changeTokenPressed = PassthroughSubject<Void, Never>()

    @Published var title: String
    @Published var amount: Double?
    @Published var amountTextColor = Asset.Colors.night.color
    @Published var isFirstResponder: Bool
    @Published var isEditable: Bool
    @Published var balance: Double?
    @Published var balanceText = ""
    @Published var tokenSymbol = ""
    @Published var isLoading = false
    @Published var isAmountLoading = false
    @Published var fiatAmount: String?
    @Published var token: SwapToken

    private let stateMachine: JupiterSwapStateMachine
    private let isFromToken: Bool
    private var currentState: JupiterSwapState { stateMachine.currentState }

    @Injected private var notificationService: NotificationService

    init(stateMachine: JupiterSwapStateMachine, isFromToken: Bool) {
        self.isFromToken = isFromToken
        self.stateMachine = stateMachine

        self.title = isFromToken ? L10n.youPay : L10n.youReceive
        self.isFirstResponder = isFromToken
        self.isEditable = isFromToken
        self.token = stateMachine.currentState.fromToken

        super.init()

        allButtonPressed
            .sink { [unowned self] _ in
                self.amount = self.balance
            }
            .store(in: &subscriptions)

        $token
            .sink { [unowned self] value in
                self.tokenSymbol = value.jupiterToken.symbol
                self.balance = value.userWallet?.amount
            }
            .store(in: &subscriptions)

        $balance
            .sink { [unowned self] value in
                self.balanceText = value?.toString(maximumFractionDigits: self.token.jupiterToken.decimals) ?? "0"
            }
            .store(in: &subscriptions)

        $amount
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] value in
                guard let self, self.isStateReady(status: self.currentState.status) else { return }
                self.isAmountLoading = true && !self.isFromToken
                if self.isFromToken {
                    let _ = await self.stateMachine.accept(action: .changeAmountFrom(value ?? 0))
                }
                self.isAmountLoading = false && !self.isFromToken
            }
            .store(in: &subscriptions)

        stateMachine.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedState in
                guard let self else { return }
                self.token = self.isFromToken ? updatedState.fromToken : updatedState.toToken
                self.updateLoading(status: updatedState.status)

                if self.isFromToken {
                    self.updateAmountFrom(state: updatedState)
                } else {
                    self.updateAmountTo(state: updatedState)
                }
            }
            .store(in: &subscriptions)

        amountFieldTap
            .sink { [unowned self] in
                guard !self.isEditable else { return }
                self.notificationService.showToast(title: "🤖", text: L10n.youCanEnterYouPayFieldOnly)
            }
            .store(in: &subscriptions)
    }
}

private extension SwapInputViewModel {
    func updateLoading(status: JupiterSwapState.Status) {
        switch status {
        case .requiredInitialize, .initializing:
            isLoading = true
        case .loadingAmountTo:
            isAmountLoading = isFromToken ? false : true
        case .loadingTokenTo:
            isLoading = isFromToken ? false : true
        case .switching:
            isLoading = true
        default:
            isLoading = false
            isAmountLoading = false
        }
    }

    func updateAmountTo(state: JupiterSwapState) {
        guard state.status != .loadingAmountTo else { return }
        amount = state.amountTo
    }

    func updateAmountFrom(state: JupiterSwapState) {
        switch state.status {
        case .error(reason: .notEnoughFromToken):
            amountTextColor = Asset.Colors.rose.color
        default:
            amountTextColor = Asset.Colors.night.color
        }

        fiatAmount = [
            state.amountFromFiat.toString(maximumFractionDigits: 2, roundingMode: .down),
            Defaults.fiat.code
        ].joined(separator: " ")
    }

    func isStateReady(status: JupiterSwapState.Status) -> Bool {
        return status != .requiredInitialize && status != .initializing && status != .error(reason: .initializationFailed)
    }
}
