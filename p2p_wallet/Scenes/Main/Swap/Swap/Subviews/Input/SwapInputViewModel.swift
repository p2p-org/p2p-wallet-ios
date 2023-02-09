import Combine

final class SwapInputViewModel: BaseViewModel, ObservableObject {
    @Published var title: String
    @Published var amountText: String
    @Published var isFirstResponder: Bool
    @Published var isEditable: Bool
    @Published var balance: Double?
    @Published var balanceText: String?
    @Published var tokenSymbol: String
    @Published var isLoading: Bool = false
    @Published var fiatAmount: String?

    let allButtonPressed = PassthroughSubject<Void, Never>()
    let changeTokenPressed = PassthroughSubject<Void, Never>()

    init(title: String, isFirstResponder: Bool, isEditable: Bool, balance: Double?, tokenSymbol: String) {
        self.title = title
        self.amountText = ""
        self.isFirstResponder = isFirstResponder
        self.isEditable = isEditable
        self.balance = balance
        self.tokenSymbol = tokenSymbol
        self.balanceText = balance?.tokenAmountFormattedString(symbol: tokenSymbol)

        super.init()

        allButtonPressed
            .sink { [unowned self] _ in
                self.amountText = "\(self.balance ?? 0)"
            }
            .store(in: &subscriptions)
    }

    func update(swapToken: SwapToken) {
        self.balance = swapToken.wallet?.amount
        self.tokenSymbol = swapToken.jupiterToken.symbol
        self.balanceText = balance?.tokenAmountFormattedString(symbol: tokenSymbol)
    }
}

extension SwapInputViewModel {
    static func buildFromViewModel(swapToken: SwapToken) -> SwapInputViewModel {
        SwapInputViewModel(title: L10n.youPay, isFirstResponder: true, isEditable: true, balance: swapToken.wallet?.amount, tokenSymbol: swapToken.jupiterToken.symbol)
    }

    static func buildToViewModel(swapToken: SwapToken) -> SwapInputViewModel {
        SwapInputViewModel(title: L10n.youReceive, isFirstResponder: false, isEditable: false, balance: swapToken.wallet?.amount, tokenSymbol: swapToken.jupiterToken.symbol)
    }
}
