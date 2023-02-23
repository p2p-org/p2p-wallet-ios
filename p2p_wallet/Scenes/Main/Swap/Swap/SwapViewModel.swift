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
    @Injected private var userWalletManager: UserWalletManager

    // MARK: - Actions
    let switchTokens = PassthroughSubject<Void, Never>()
    let tryAgain = PassthroughSubject<Void, Never>()
    let changeFromToken = PassthroughSubject<SwapToken, Never>()
    let changeToToken = PassthroughSubject<SwapToken, Never>()
    let submitTransaction = PassthroughSubject<PendingTransaction, Never>()

    // MARK: - Params
    @Published var header: String = ""
    @Published var initializingState: InitializingState = .loading
    @Published var arePricesLoading: Bool = false

    @Published var priceInfo = SwapPriceInfo(fromPrice: 0, toPrice: 0)
    private var priceInfoTask: Task<Void, Never>?

    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false {
        didSet {
            sendToken()
        }
    }
    @Published var showFinished = false

    var versionedTransaction: VersionedTransaction? //  I think it should be placed inside StateMachine rn
    var toTokens: [SwapToken] = [] //  I think it should be placed inside StateMachine rn

    let stateMachine: JupiterSwapStateMachine
    var currentState: JupiterSwapState { stateMachine.currentState }
    
    private let preChosenWallet: Wallet?
    private var timer: Timer?

    init(preChosenWallet: Wallet? = nil) {
        stateMachine = JupiterSwapStateMachine(
            initialState: .zero(status: .requiredInitialize),
            services: JupiterSwapServices(
                jupiterClient: JupiterRestClientAPI(version: .v4),
                pricesAPI: Resolver.resolve(),
                solanaAPIClient: Resolver.resolve()
            )
        )
        self.preChosenWallet = preChosenWallet
        super.init()
        bind()
        bindActions()
    }

    deinit {
        timer?.invalidate()
    }
}

private extension SwapViewModel {
    func bind() {
        swapWalletsRepository.status
            .sinkAsync { [weak self] dataStatus in
                guard let self else { return }
                switch dataStatus {
                case .loading, .initial:
                    self.initializingState = .loading
                case let .ready(swapTokens, routeMap):
                    let prechosenToken = swapTokens.first(where: { $0.address == self.preChosenWallet?.mintAddress })
                    self.getToTokens(routeMap: routeMap)
                    let _ = await self.stateMachine
                        .accept(action: .initialize(
                            swapTokens: swapTokens,
                            routeMap: routeMap,
                            fromToken: prechosenToken
                        ))
                case .failed:
                    self.initializingState = .failed
                }
                
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
        case .requiredInitialize:
            break
        case .initializing:
            initializingState = .loading
        case .error(.initializationFailed):
            initializingState = .failed
        default:
            scheduleUpdate()
            initializingState = .success
        }

        switch status {
        case .initializing, .loadingTokenTo, .loadingAmountTo, .switching:
            arePricesLoading = true
        default:
            arePricesLoading = false
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
            .sinkAsync { [weak self] _ in
                guard let self else { return }
                if self.currentState.swapTokens.isEmpty {
                    await self.swapWalletsRepository.load()
                } else {
                    let _ = await self.stateMachine.accept(action: .initialize(swapTokens: self.currentState.swapTokens, routeMap: self.currentState.routeMap, fromToken: self.currentState.fromToken))
                }
            }
            .store(in: &subscriptions)
    }

    func scheduleUpdate() {
        cancelUpdate()
        timer = .scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task {
                let _ = await self?.stateMachine.accept(action: .update)
            }
        }
    }

    func cancelUpdate() {
        timer?.invalidate()
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
        case .error(.networkConnectionError):
            notificationService.showConnectionErrorNotification()
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.swapOfTheseTokensIsnTPossible)
        default:
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.swapOfTheseTokensIsnTPossible)
        }
    }

    private func getToTokens(routeMap: RouteMap) {
        let selectedFromAddress = currentState.fromToken.jupiterToken.address
        let toAddresses = Set(routeMap.indexesRouteMap[selectedFromAddress] ?? [])
        let toTokens = currentState.swapTokens.filter { toAddresses.contains($0.jupiterToken.address) }
        self.toTokens = toTokens
    }

    private func swapToken() async throws {
        guard let route = stateMachine.currentState.route else { return }

        let account = userWalletManager.wallet!.account
        let pubKey = account.publicKey.base58EncodedString
        let jupiterClient = stateMachine.services.jupiterClient

        versionedTransaction = try await jupiterClient.swap(
            route: route,
            userPublicKey: pubKey,
            wrapUnwrapSol: true, feeAccount: nil, asLegacyTransaction: nil,
            computeUnitPriceMicroLamports: nil, destinationWallet: nil
        )
    }

    private func sendToken() {
        guard isSliderOn, let versionedTransaction = versionedTransaction, let account = userWalletManager.wallet?.account else { return }
        cancelUpdate()
        let pendingTransaction = PendingTransaction(
            trxIndex: 0,
            sentAt: Date(),
            rawTransaction: JupiterSwapTransaction(
                execution: {
                    let solanaAPIClient = Resolver.resolve(SolanaAPIClient.self)
                    let blockHash = try await solanaAPIClient.getRecentBlockhash()
                    var versionedTransaction = versionedTransaction
                    versionedTransaction.setRecentBlockHash(blockHash)
                    try versionedTransaction.sign(signers: [account])
                    
                    let serializedTransaction = try versionedTransaction.serialize().base64EncodedString()
                    
                    return try await solanaAPIClient.sendTransaction(
                        transaction: serializedTransaction,
                        configs: RequestConfiguration(encoding: "base64")!
                    )
                },
                amountFrom: currentState.amountFrom,
                amountTo: currentState.amountTo,
                fromToken: currentState.fromToken,
                toToken: currentState.toToken,
                amountFromFiat: currentState.amountFromFiat
            ),
            status: .sending
        )
        submitTransaction.send(pendingTransaction)
    }
}
