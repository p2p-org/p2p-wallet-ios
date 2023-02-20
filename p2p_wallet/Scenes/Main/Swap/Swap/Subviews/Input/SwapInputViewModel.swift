import Combine
import Resolver

final class SwapInputViewModel: BaseViewModel, ObservableObject {

    let allButtonPressed = PassthroughSubject<Void, Never>()
    let amountFieldTap = PassthroughSubject<Void, Never>()
    let changeTokenPressed = PassthroughSubject<Void, Never>()

    @Published var title: String
    @Published var amountText: String = ""
    @Published var isFirstResponder: Bool
    @Published var isEditable: Bool
    @Published var balance: Double?
    @Published var balanceText: String = ""
    @Published var tokenSymbol: String = ""
    @Published var isLoading: Bool = false
    @Published var isAmountLoading: Bool = false
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
                self.amountText = "\(self.balance ?? 0)"
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

        $amountText
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] value in
                guard let self = self else { return }
                self.isAmountLoading = true && !self.isFromToken
                if self.isFromToken {
                    let _ = await self.stateMachine.accept(action: .changeAmountFrom(Double(value) ?? 0))
                }
                self.isAmountLoading = false && !self.isFromToken
            }
            .store(in: &subscriptions)

        stateMachine.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedState in
                guard let self else { return }
                self.token = self.isFromToken ? updatedState.fromToken : updatedState.toToken

                if self.isFromToken {
                    self.fiatAmount = "\((updatedState.priceInfo.fromPrice * updatedState.amountFrom).toString(maximumFractionDigits: 2, roundingMode: .down)) \(Defaults.fiat.code)"
                } else {
                    self.amountText = updatedState.amountTo.toString(
                        maximumFractionDigits: updatedState.toToken.jupiterToken.decimals,
                        roundingMode: .down
                    )
                }
                self.updateLoading(status: updatedState.status)
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
            self.isLoading = true
        case .loadingAmountTo:
            self.isAmountLoading = isFromToken ? false : true
        case .loadingTokenTo:
            self.isLoading = isFromToken ? false : true
        case .switching:
            self.isLoading = true
        default:
            self.isLoading = false
            self.isAmountLoading = false
        }
    }
}
