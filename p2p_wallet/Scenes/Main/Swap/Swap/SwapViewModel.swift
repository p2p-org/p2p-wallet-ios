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
    @Injected private var transactionHandler: TransactionHandler

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

    var versionedTransaction: VersionedTransaction? //  I think it should be placed inside StateMachine rn (need to conform VersionedTransaction to Equatable to do that)

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
    
    func update() async {
        let _ = await stateMachine.accept(action: .update)
    }
    
    #if !RELEASE
    func getRouteInSymbols() -> String? {
        let tokensList = stateMachine.currentState.swapTokens.map(\.token)
        return stateMachine.currentState.route?.toSymbols(tokensList: tokensList)
    }
    #endif
}

private extension SwapViewModel {
    func bind() {
        Resolver.resolve(WalletsRepository.self)
            .dataPublisher
            .sinkAsync { [weak self] userWallets in
                let _ = await self?.stateMachine.accept(action: .updateUserWallets(userWallets: userWallets))
            }
            .store(in: &subscriptions)
        
        swapWalletsRepository.status
            .sinkAsync { [weak self] dataStatus in
                guard let self else { return }
                switch dataStatus {
                case .loading, .initial:
                    self.initializingState = .loading
                case let .ready(swapTokens, routeMap):
                    let prechosenToken = swapTokens.first(where: { $0.address == self.preChosenWallet?.mintAddress })
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
                self.handle(state: updatedState)
                self.updateHeader(priceInfo: updatedState.priceInfo, fromToken: updatedState.fromToken.token, toToken: updatedState.toToken.token)
                self.updateActionButton(for: updatedState)
            }
            .store(in: &subscriptions)
    }

    func handle(state: JupiterSwapState) {
        switch state.status {
        case .requiredInitialize, .initializing:
            self.initializingState = .loading
        case .error(.initializationFailed):
            initializingState = .failed
        default:
            scheduleUpdate()
            initializingState = .success
        }

        switch state.status {
        case .requiredInitialize, .initializing, .loadingTokenTo, .loadingAmountTo, .switching:
            arePricesLoading = true
        case .ready:
            arePricesLoading = false
            guard state.amountFrom > 0 else { return }
            Task {
                actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.counting)
                do {
                    try await swapToken()
                    actionButtonData = SliderActionButtonData(
                        isEnabled: true,
                        title: L10n.swap(state.fromToken.token.symbol, state.toToken.token.symbol)
                    )
                } catch {
                    actionButtonData = SliderActionButtonData(
                        isEnabled: false,
                        title: L10n.swapOfTheseTokensIsnTPossible
                    )
                }
            }
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
        timer = .scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
            Task { [weak self] in
                await self?.update()
            }
        }
    }

    func cancelUpdate() {
        timer?.invalidate()
    }

    func updateHeader(priceInfo: SwapPriceInfo, fromToken: Token, toToken: Token) {
        if priceInfo.relation != 0 {
            let onetoToken = 1.tokenAmountFormattedString(symbol: toToken.symbol, maximumFractionDigits: Int(toToken.decimals), roundingMode: .down)
            let amountFromToken = priceInfo.relation.tokenAmountFormattedString(symbol: fromToken.symbol, maximumFractionDigits: Int(fromToken.decimals), roundingMode: .down)
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
            }
        case .requiredInitialize, .loadingTokenTo, .loadingAmountTo, .switching, .initializing:
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.counting)
        case .error(.notEnoughFromToken):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.notEnough(state.fromToken.token.symbol))
        case .error(.equalSwapTokens):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.youCanTSwapSameToken)
        case .error(.networkConnectionError):
            notificationService.showConnectionErrorNotification()
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.swapOfTheseTokensIsnTPossible)
        default:
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.swapOfTheseTokensIsnTPossible)
        }
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
        // assertion
        guard isSliderOn,
              let versionedTransaction = versionedTransaction,
              let account = userWalletManager.wallet?.account,
              let sourceWallet = currentState.fromToken.userWallet
        else { return }
        
        // cancel updating
        cancelUpdate()
        
        // form transaction
        let destinationWallet = currentState.toToken.userWallet ?? Wallet(pubkey: nil, token: currentState.toToken.token)
        
        let swapTransaction = JupiterSwapTransaction(
            authority: account.publicKey.base58EncodedString,
            amountFrom: currentState.amountFrom,
            amountTo: currentState.amountTo,
            sourceWallet: sourceWallet,
            destinationWallet: destinationWallet,
            fromAmount: currentState.amountFrom,
            toAmount: currentState.amountTo,
            slippage: 0.01, // FIXME: - actual slippage,
            metaInfo: SwapMetaInfo(
                swapMAX: false, // FIXME: - Swap max or not
                swapUSD: 0 // FIXME:
            ),
            payingFeeWallet: nil, // FIXME: - PayingFeeWallet
            feeAmount: .zero, // FIXME: - feeAmount
            execution: { [unowned self] in
                do {
                    let transactionId = try await JupiterSwapBusinessLogic.sendToBlockchain(
                        account: account,
                        versionedTransaction: versionedTransaction,
                        solanaAPIClient: stateMachine.services.solanaAPIClient
                    )
                    debugPrint("---transactionId: ", transactionId)
                    self.isSliderOn = false
                    return transactionId
                } catch {
                    debugPrint("---errorSendingTransaction: ", error)
                    self.isSliderOn = false
                    throw error
                }
            })
        
        let transactionIndex = transactionHandler.sendTransaction(
            swapTransaction
        )
        
        let pendingTransaction = PendingTransaction(
            trxIndex: transactionIndex,
            sentAt: Date(),
            rawTransaction: swapTransaction,
            status: .sending
        )
        submitTransaction.send(pendingTransaction)
    }
}
