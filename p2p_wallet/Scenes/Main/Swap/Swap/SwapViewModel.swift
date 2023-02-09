import Combine
import Resolver
import Jupiter
import SolanaPricesAPIs
import SolanaSwift

final class SwapViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies
    @Injected private var swapWalletsRepository: SwapWalletsRepository
    @Injected private var pricesAPI: SolanaPricesAPI
    @Injected private var notificationService: NotificationService

    // MARK: - Actions
    let switchTokens = PassthroughSubject<Void, Never>()

    // MARK: - Params
    @Published var header: String = ""
    @Published var isLoading: Bool = false
    @Published var arePricesLoading: Bool = false

    @Published var fromToken: SwapToken = .init(jupiterToken: .nativeSolana, wallet: nil)
    @Published var toToken: SwapToken = .init(jupiterToken: .usdc, wallet: nil)
    @Published var priceInfo = SwapPriceInfo(fromPrice: 0, toPrice: 0)
    private var priceInfoTask: Task<Void, Never>?

    // MARK: - Subviewmodels
    let fromTokenViewModel: SwapInputViewModel
    let toTokenViewModel: SwapInputViewModel
    let actionButtonViewModel: SliderActionButtonViewModel

    override init() {
        self.fromTokenViewModel = SwapInputViewModel.buildFromViewModel(swapToken: .init(jupiterToken: .usdc, wallet: nil))
        self.toTokenViewModel = SwapInputViewModel.buildToViewModel(swapToken: .init(jupiterToken: .usdc, wallet: nil))
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
                self.fromTokenViewModel.fiatAmount = (self.priceInfo.fromPrice * amount).fiatAmountFormattedString()
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
                self?.isLoading = currentState == .loading
            }
            .store(in: &subscriptions)

        swapWalletsRepository.tokens
            .receive(on: RunLoop.main)
            .sink { [weak self] data in
                self?.prepareTokens(data: data)
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
            .sink { [weak self] token in
                self?.fromTokenViewModel.update(swapToken: token)
            }
            .store(in: &subscriptions)

        $toToken
            .sink { [weak self] token in
                self?.toTokenViewModel.update(swapToken: token)
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest($fromToken.eraseToAnyPublisher(), $toToken.eraseToAnyPublisher())
            .sink(receiveValue: { [weak self] fromToken, toToken in
                debugPrint(fromToken.jupiterToken.symbol)
                debugPrint(toToken.jupiterToken.symbol)
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

    func prepareTokens(data: SwapWalletsData) {
        let walletUSDC = data.userTokens.first(where: { $0.mintAddress == Token.usdc.address })
        let walletSolana = data.userTokens.first(where: { $0.mintAddress == Token.nativeSolana.address })
        let jupiterUSDC = data.alljupiterTokens.first(where: { $0.address == Token.usdc.address })
        let jupiterSolana = data.alljupiterTokens.first(where: { $0.address == Token.nativeSolana.address })

        if data.userTokens.isEmpty, let jupiterUSDC, let jupiterSolana {
            fromToken = SwapToken(jupiterToken: jupiterUSDC, wallet: walletUSDC)
            toToken = SwapToken(jupiterToken: jupiterSolana, wallet: walletSolana)
        } else if let walletUSDC, let jupiterUSDC, let jupiterSolana {
            fromToken = SwapToken(jupiterToken: jupiterUSDC, wallet: walletUSDC)
            toToken = SwapToken(jupiterToken: jupiterSolana, wallet: walletSolana)
        } else if let walletSolana, let jupiterUSDC, let jupiterSolana {
            fromToken = SwapToken(jupiterToken: jupiterSolana, wallet: walletSolana)
            toToken = SwapToken(jupiterToken: jupiterUSDC, wallet: walletUSDC)
        } else if let jupiterUSDC {
            let biggestUserToken = data.userTokens.sorted(by: { $0.amountInCurrentFiat > $1.amountInCurrentFiat }).first
            fromToken = SwapToken(jupiterToken: data.alljupiterTokens.first(where: { $0.address == biggestUserToken?.mintAddress }) ?? jupiterSolana ?? jupiterUSDC, wallet: biggestUserToken)
            toToken = SwapToken(jupiterToken: jupiterUSDC, wallet: walletUSDC)
        }
    }

    func getPrices(from: SwapToken, to: SwapToken) {
        guard from.jupiterToken.address != to.jupiterToken.address else { return }
        priceInfoTask?.cancel()
        arePricesLoading = true
        priceInfoTask = Task {
            do {
                let prices = try await pricesAPI.getCurrentPrices(coins: [from.jupiterToken, to.jupiterToken], toFiat: Defaults.fiat.code)
                let fromPrice = prices[from.jupiterToken]??.value
                let toPrice = prices[to.jupiterToken]??.value
                self.priceInfo = SwapPriceInfo(fromPrice: fromPrice ?? 0, toPrice: toPrice ?? 0)
                self.arePricesLoading = false
            }
            catch {
                self.priceInfo = SwapPriceInfo(fromPrice: 0, toPrice: 0)
                self.arePricesLoading = false
            }
        }
    }
}
