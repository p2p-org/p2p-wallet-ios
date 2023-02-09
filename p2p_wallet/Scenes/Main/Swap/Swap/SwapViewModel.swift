import Combine

final class SwapViewModel: BaseViewModel, ObservableObject {

    let switchTokens = PassthroughSubject<Void, Never>()

    @Published var header: String = ""
    @Published var isLoading: Bool = false

    let fromTokenViewModel: SwapInputViewModel
    let toTokenViewModel: SwapInputViewModel
    let actionButtonViewModel: SliderActionButtonViewModel

    override init() {
        self.fromTokenViewModel = SwapInputViewModel.buildFromViewModel(balance: 16.28, tokenSymbol: "USDC")
        self.toTokenViewModel = SwapInputViewModel.buildToViewModel(balance: 7.59, tokenSymbol: "SOL")

        self.actionButtonViewModel = SliderActionButtonViewModel()

        super.init()

        header = "1 SOL ≈ 12.85 USD"

        fromTokenViewModel.$amountText
            .sink { [unowned self] value in
                self.toTokenViewModel.amountText = "\(Double(value) * 2)"
                self.fromTokenViewModel.fiatAmount = Double(value)?.fiatAmountFormattedString()
            }
            .store(in: &subscriptions)

        switchTokens
            .sink { [unowned self] _ in
                let fromSymbol = self.fromTokenViewModel.tokenSymbol
                self.fromTokenViewModel.tokenSymbol = self.toTokenViewModel.tokenSymbol
                self.toTokenViewModel.tokenSymbol = fromSymbol
            }
            .store(in: &subscriptions)

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: { self.isLoading = false })

        $isLoading
            .sink { [weak self] value in
                self?.fromTokenViewModel.isLoading = value
                self?.toTokenViewModel.isLoading = value

                if value {
                    self?.actionButtonViewModel.actionButton = .init(isEnabled: false, title: L10n.counting)
                } else {
                    self?.actionButtonViewModel.actionButton = .init(isEnabled: false, title: L10n.enterTheAmount)
                }
            }
            .store(in: &subscriptions)
    }
}
