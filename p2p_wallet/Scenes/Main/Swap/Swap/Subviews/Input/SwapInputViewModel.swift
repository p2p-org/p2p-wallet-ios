import Combine

final class SwapInputViewModel: BaseViewModel, ObservableObject {

    @Published var title: String
    @Published var amountText: String
    @Published var isFirstResponder: Bool
    @Published var isEditable: Bool
    @Published var balance: Double?
    @Published var balanceText: String = ""
    @Published var tokenSymbol: String = ""
    @Published var isLoading: Bool = false
    @Published var isAmountLoading: Bool = false
    @Published var fiatAmount: String?
    @Published var token: SwapToken

    let allButtonPressed = PassthroughSubject<Void, Never>()
    let changeTokenPressed = PassthroughSubject<Void, Never>()
    let amountFieldTap = PassthroughSubject<Void, Never>()

    init(title: String, isFirstResponder: Bool, isEditable: Bool, token: SwapToken) {
        self.title = title
        self.amountText = ""
        self.isFirstResponder = isFirstResponder
        self.isEditable = isEditable
        self.token = token
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
    }
}

extension SwapInputViewModel {
    static func buildFromViewModel(swapToken: SwapToken) -> SwapInputViewModel {
        SwapInputViewModel(title: L10n.youPay, isFirstResponder: true, isEditable: true, token: swapToken)
    }

    static func buildToViewModel(swapToken: SwapToken) -> SwapInputViewModel {
        SwapInputViewModel(title: L10n.youReceive, isFirstResponder: false, isEditable: false, token: swapToken)
    }
}
