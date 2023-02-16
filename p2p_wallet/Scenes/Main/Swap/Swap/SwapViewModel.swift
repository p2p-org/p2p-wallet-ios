import Combine
import Resolver
import Jupiter
import SolanaPricesAPIs
import SolanaSwift

final class SwapViewModel: BaseViewModel, ObservableObject {

    enum InitializingState {
        case loading
        case failed
        case success
    }

    // MARK: - Dependencies
    @Injected private var swapWalletsRepository: JupiterTokensRepository
    @Injected private var pricesAPI: SolanaPricesAPI
    @Injected private var notificationService: NotificationService

    // MARK: - Actions
    let switchTokens = PassthroughSubject<Void, Never>()
    let tryAgain = PassthroughSubject<Void, Never>()
    let changeFromToken = PassthroughSubject<SwapToken, Never>()
    let changeToToken = PassthroughSubject<SwapToken, Never>()

    // MARK: - Params
    @Published var header: String = ""
    @Published var initializingState: InitializingState = .loading
    @Published var arePricesLoading: Bool = false

    // MARK: - Subviewmodels
    let fromTokenViewModel: SwapInputViewModel
    let toTokenViewModel: SwapInputViewModel
    let actionButtonViewModel: SliderActionButtonViewModel

    let stateMachine: JupiterSwapStateMachine
    var currentState: JupiterSwapState { stateMachine.currentState }

    override init() {
        self.fromTokenViewModel = SwapInputViewModel.buildFromViewModel(swapToken: .nativeSolana)
        self.toTokenViewModel = SwapInputViewModel.buildToViewModel(swapToken: .nativeSolana)
        self.actionButtonViewModel = SliderActionButtonViewModel()

        stateMachine = .init(
            initialState: JupiterSwapState.zero(status: .requiredInitialize),
            services: .init(jupiterClient: JupiterRestClientAPI(version: .v4), pricesAPI: Resolver.resolve())
        )

        super.init()
        bind()
        bindActions()
    }
}

private extension SwapViewModel {
    func bind() {
        fromTokenViewModel.$amountText
            .sinkAsync {  [unowned self] value in
                let amount = Double(value) ?? 0
                let _ = await self.stateMachine.accept(action: .changeAmountFrom(amount))
            }
            .store(in: &subscriptions)

        swapWalletsRepository.data
            .sinkAsync { [weak self] data in
                let _ = await self?.stateMachine
                    .accept(action: .initialize(swapTokens: data.swapTokens, routeMap: data.routeMap))
            }
            .store(in: &subscriptions)

        $initializingState
            .sink { [weak self] value in
                self?.fromTokenViewModel.isLoading = value == .loading
                self?.toTokenViewModel.isLoading = value == .loading

                if value == .loading {
                    self?.actionButtonViewModel.actionButton = .init(isEnabled: false, title: L10n.counting)
                } else {
                    self?.actionButtonViewModel.actionButton = .init(isEnabled: false, title: L10n.enterTheAmount)
                }
            }
            .store(in: &subscriptions)

        changeFromToken
            .sinkAsync { [weak self] token in
                self?.arePricesLoading = true
                let _ = await self?.stateMachine.accept(action: .changeFromToken(token))
                self?.arePricesLoading = false
            }
            .store(in: &subscriptions)

        changeToToken
            .sinkAsync { [ weak self] token in
                self?.arePricesLoading = true
                let _ = await self?.stateMachine.accept(action: .changeToToken(token))
                self?.arePricesLoading = false
            }
            .store(in: &subscriptions)

        stateMachine.statePublisher
            .sinkAsync { [weak self] updatedState in
                guard let self else { return }
                debugPrint(updatedState.status)
                self.updateInitializingState(status: updatedState.status)

                self.fromTokenViewModel.token = updatedState.fromToken
                self.toTokenViewModel.token = updatedState.toToken

                self.updateHeader(priceInfo: updatedState.priceInfo, fromToken: updatedState.fromToken, toToken: updatedState.toToken)
                self.update(amount: updatedState.amountTo, toToken: updatedState.toToken)

                self.fromTokenViewModel.fiatAmount = "\((updatedState.priceInfo.fromPrice * updatedState.amountFrom).toString(maximumFractionDigits: 2, roundingMode: .down)) \(Defaults.fiat.code)"

            }
            .store(in: &subscriptions)
    }

    func updateInitializingState(status: JupiterSwapState.Status) {
        switch status {
        case .requiredInitialize:
            self.initializingState = .loading
        case .ready:
            self.initializingState = .success
        case .error(.initializationFailed):
            self.initializingState = .failed
        case .error:
            break
        }
    }

    func bindActions() {
        switchTokens
            .sinkAsync(receiveValue: { [weak self] _ in
                guard let self else { return }
                let _ = await self.stateMachine.accept(action: .changeBothTokens(from: self.currentState.toToken, to: self.currentState.fromToken))
            })
            .store(in: &subscriptions)

        tryAgain
            .sinkAsync { [weak self] in
                guard let self else { return }
            }
            .store(in: &subscriptions)
    }

    func updateHeader(priceInfo: SwapPriceInfo, fromToken: SwapToken, toToken: SwapToken) {
        if priceInfo.relation != 0 {
            self.header = "\(1.tokenAmountFormattedString(symbol: toToken.jupiterToken.symbol, maximumFractionDigits: toToken.jupiterToken.decimals)) ≈ \(priceInfo.relation.tokenAmountFormattedString(symbol: fromToken.jupiterToken.symbol, maximumFractionDigits: fromToken.jupiterToken.decimals))"
        } else {
            self.header = ""
        }
    }

    func update(amount: Double, toToken: SwapToken) {
        self.toTokenViewModel.amountText = amount.toString(maximumFractionDigits: toToken.jupiterToken.decimals, roundingMode: .down)
        
    }
}
