import Combine
import Resolver
import Jupiter
import SolanaPricesAPIs
import SolanaSwift

final class SwapViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies
    @Injected private var swapWalletsRepository: JupiterTokensRepository
    @Injected private var pricesAPI: SolanaPricesAPI
    @Injected private var notificationService: NotificationService

    // MARK: - Actions
    let switchTokens = PassthroughSubject<Void, Never>()

    // MARK: - Params
    @Published var header: String = ""
    @Published var isLoading: Bool = false
    @Published var arePricesLoading: Bool = false

    @Published var fromToken: SwapToken = .nativeSolana
    @Published var toToken: SwapToken = .nativeSolana
    @Published var priceInfo = SwapPriceInfo(fromPrice: 0, toPrice: 0)
    private var priceInfoTask: Task<Void, Never>?

    // MARK: - Subviewmodels
    let fromTokenViewModel: SwapInputViewModel
    let toTokenViewModel: SwapInputViewModel
    let actionButtonViewModel: SliderActionButtonViewModel
    
    var tokens: [SwapToken] = []

    override init() {
        self.fromTokenViewModel = SwapInputViewModel.buildFromViewModel(swapToken: .nativeSolana)
        self.toTokenViewModel = SwapInputViewModel.buildToViewModel(swapToken: .nativeSolana)
        self.actionButtonViewModel = SliderActionButtonViewModel()
        super.init()
        bind()
    }
}

private extension SwapViewModel {
    func bind() {
        fromTokenViewModel.$amountText
            .sink { [unowned self] value in
                let amount = Double(value) ?? 0
                self.toTokenViewModel.amountText = (amount * self.priceInfo.relation).toString(maximumFractionDigits: Int(self.toToken.jupiterToken.decimals), roundingMode: .down)
                self.fromTokenViewModel.fiatAmount = "\((self.priceInfo.fromPrice * amount).toString(maximumFractionDigits: 2, roundingMode: .down)) \(Defaults.fiat.code)"
            }
            .store(in: &subscriptions)

        switchTokens
            .sink { [unowned self] _ in
                let fromHolder = self.fromToken
                self.fromToken = self.toToken
                self.toToken = fromHolder
            }
            .store(in: &subscriptions)

        swapWalletsRepository.state
            .sink { [weak self] currentState in
                self?.isLoading = currentState == .loading || currentState == .initialized
            }
            .store(in: &subscriptions)

        swapWalletsRepository.tokens
            .sinkAsync { [weak self] data in
                self?.autoChooseSwapTokens(data: data)
            }
            .store(in: &subscriptions)

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

        $fromToken
            .sink { [weak fromTokenViewModel] token in
                fromTokenViewModel?.token = token
            }
            .store(in: &subscriptions)

        $toToken
            .sink { [weak toTokenViewModel] token in
                toTokenViewModel?.token = token
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest($fromToken.eraseToAnyPublisher(), $toToken.eraseToAnyPublisher())
            .sink(receiveValue: { [weak self] fromToken, toToken in
                self?.getPrices(from: fromToken, to: toToken)
            })
            .store(in: &subscriptions)

        $priceInfo
            .sink { [weak self] info in
                guard let self else { return }
                if info.relation != 0 {
                    self.header = "\(1.tokenAmountFormattedString(symbol: self.fromToken.jupiterToken.symbol, maximumFractionDigits: Int(self.fromToken.jupiterToken.decimals))) ≈ \(info.relation.tokenAmountFormattedString(symbol: self.toToken.jupiterToken.symbol, maximumFractionDigits: Int(self.toToken.jupiterToken.decimals)))"
                } else {
                    self.header = ""
                }
            }
            .store(in: &subscriptions)
    }

    func autoChooseSwapTokens(data: JupiterTokensData) {
        self.tokens = data.tokens
        let usdc = data.tokens.first(where: { $0.jupiterToken.address == Token.usdc.address })
        let solana = data.tokens.first(where: { $0.jupiterToken.address == Token.nativeSolana.address })

        if data.userWallets.isEmpty, let usdc, let solana {
            fromToken = usdc
            toToken = solana
        } else if usdc?.userWallet != nil, let usdc, let solana {
            fromToken = usdc
            toToken = solana
        } else if solana?.userWallet != nil, let usdc, let solana {
            fromToken = solana
            toToken = usdc
        } else if let usdc {
            let userWallet = data.userWallets.sorted(by: { $0.amountInCurrentFiat > $1.amountInCurrentFiat }).first
            let swapToken = data.tokens.first(where: { $0.jupiterToken.address == userWallet?.mintAddress })
            fromToken = swapToken ?? solana ?? usdc
            toToken = usdc
        }
    }

    func getPrices(from: SwapToken, to: SwapToken) {
        guard from.jupiterToken.address != to.jupiterToken.address else { return }

        priceInfoTask?.cancel()
        arePricesLoading = true
        priceInfoTask = Task {
            do {
                let fromToken = SolanaSwift.Token.init(jupiterToken: from.jupiterToken)
                let toToken = SolanaSwift.Token.init(jupiterToken: to.jupiterToken)
                let prices = try await pricesAPI.getCurrentPrices(coins: [fromToken, toToken], toFiat: Defaults.fiat.code)
                self.priceInfo = SwapPriceInfo(fromPrice: prices[fromToken]??.value ?? 0, toPrice: prices[toToken]??.value ?? 0)
                self.arePricesLoading = false
            }
            catch {
                self.priceInfo = SwapPriceInfo(fromPrice: 0, toPrice: 0)
                self.arePricesLoading = false
            }
        }
    }
}

private extension SwapToken {
    static let nativeSolana = SwapToken(
        jupiterToken: .init(
            address: SolanaSwift.Token.nativeSolana.address,
            chainId: SolanaSwift.Token.nativeSolana.chainId,
            decimals: Int(SolanaSwift.Token.nativeSolana.decimals),
            name: SolanaSwift.Token.nativeSolana.name,
            symbol: SolanaSwift.Token.nativeSolana.symbol,
            logoURI: SolanaSwift.Token.nativeSolana.logoURI,
            extensions: nil,
            tags: []
        ),
        userWallet: nil)
}
