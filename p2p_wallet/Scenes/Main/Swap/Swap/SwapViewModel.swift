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

    @Published var fromToken: SwapToken = .nativeSolana
    @Published var toToken: SwapToken = .nativeSolana
    @Published var priceInfo = SwapPriceInfo(fromPrice: 0, toPrice: 0)
    private var priceInfoTask: Task<Void, Never>?

    // MARK: - Subviewmodels
    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false
    @Published var showFinished = false

    var tokens = [SwapToken]()
    var toTokens: [SwapToken] {
        getToTokens()
    }

let stateMachine: JupiterSwapStateMachine
    var currentState: JupiterSwapState { stateMachine.currentState }

    override init() {
        self.stateMachine = JupiterSwapStateMachine(
            initialState: JupiterSwapState.zero(status: .requiredInitialize),
            services: .init(jupiterClient: JupiterRestClientAPI(version: .v4), pricesAPI: Resolver.resolve())
        )
self.actionButtonViewModel = SliderActionButtonViewModel()
        super.init()
        bind()
        bindActions()
    }
}

private extension SwapViewModel {
    func bind() {
        swapWalletsRepository.data
            .sinkAsync { [weak self] data in
                let _ = await self?.stateMachine
                    .accept(action: .initialize(swapTokens: data.swapTokens, routeMap: data.routeMap))
            }
            .store(in: &subscriptions)

        changeFromToken
            .sinkAsync { [weak self] token in
                let _ = await self?.stateMachine.accept(action: .changeFromToken(token))
            }
            .store(in: &subscriptions)

        changeToToken
            .sinkAsync { [ weak self] token in
                let _ = await self?.stateMachine.accept(action: .changeToToken(token))
            }
            .store(in: &subscriptions)

        stateMachine.statePublisher
            .sinkAsync { [weak self] updatedState in
                guard let self else { return }
                self.handle(status: updatedState.status)
                self.updateHeader(priceInfo: updatedState.priceInfo, fromToken: updatedState.fromToken.jupiterToken, toToken: updatedState.toToken.jupiterToken)
                self.updateActionButton(for: updatedState)
            }
            .store(in: &subscriptions)
    }

    func handle(status: JupiterSwapState.Status) {
        switch status {
        case .requiredInitialize, .initializing:
            self.initializingState = .loading
        case .error(.initializationFailed):
            self.initializingState = .failed
        default:
            self.initializingState = .success
        }

        switch status {
        case .requiredInitialize, .initializing, .loadingTokenTo, .loadingAmountTo, .switching:
            self.arePricesLoading = true
        default:
            self.arePricesLoading = false
        }
    }

    func bindActions() {
        switchTokens
            .sinkAsync(receiveValue: { [weak self] _ in
                guard let self else { return }
                let _ = await self.stateMachine.accept(
                    action: .changeBothTokens(from: self.currentState.toToken, to: self.currentState.fromToken)
                )
            })
            .store(in: &subscriptions)

        tryAgain
            .sinkAsync { [weak self] in
                guard let self else { return }
            }
            .store(in: &subscriptions)
    }

    func updateHeader(priceInfo: SwapPriceInfo, fromToken: Jupiter.Token, toToken: Jupiter.Token) {
        if priceInfo.relation != 0 {
            let onetoToken = 1.tokenAmountFormattedString(symbol: toToken.symbol, maximumFractionDigits: toToken.decimals, roundingMode: .down)
            let amountFromToken = priceInfo.relation.tokenAmountFormattedString(symbol: fromToken.symbol, maximumFractionDigits: fromToken.decimals, roundingMode: .down)
            header = [onetoToken, amountFromToken].joined(separator: " ≈ ")
        } else {
            header = ""
        }
    }

    func updateActionButton(for state: JupiterSwapState) {
        switch state.status {
        case .ready:
            if state.amountFrom == 0 {
                actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.enterTheAmount)
            } else {
                actionButtonData = SliderActionButtonData(
                    isEnabled: true,
                    title: L10n.swap(state.fromToken.jupiterToken.symbol, state.toToken.jupiterToken.symbol)
                )
            }
        case .requiredInitialize, .loadingTokenTo, .loadingAmountTo, .switching, .initializing:
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.counting)
        case .error(.notEnoughFromToken):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.notEnough(state.fromToken.jupiterToken.symbol))
        case .error(.equalSwapTokens):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.youCanTSwapSameToken)
        case .error(.routeIsNotFound):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.swapOfTheseTokensIsnTPossible)
        default:
            //TODO: Handle in error tasks like https://p2pvalidator.atlassian.net/browse/PWN-7100
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.swapOfTheseTokensIsnTPossible)
        }
    }
    
    private func getToTokens() -> [SwapToken] {
        let selectedFromAddress = fromToken.jupiterToken.address
        let routeMap = swapWalletsRepository.routeMap
        let toAddresses = Set(routeMap[selectedFromAddress] ?? [])
        let toTokens = tokens.filter { toAddresses.contains($0.jupiterToken.address) }
        return toTokens
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
