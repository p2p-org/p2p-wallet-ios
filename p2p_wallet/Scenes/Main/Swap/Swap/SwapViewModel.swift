import Combine
import Resolver
import Jupiter
import SolanaSwift
import AnalyticsManager

final class SwapViewModel: BaseViewModel, ObservableObject {

    enum InitializingState {
        case loading
        case failed
        case success
    }

    // MARK: - Dependencies
    @Injected private var swapWalletsRepository: JupiterTokensRepository
    @Injected private var notificationService: NotificationService
    @Injected private var transactionHandler: TransactionHandler
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var userWalletManager: UserWalletManager

    // MARK: - Actions
    let switchTokens = PassthroughSubject<Void, Never>()
    let tryAgain = PassthroughSubject<Void, Never>()
    let changeFromToken = PassthroughSubject<SwapToken, Never>()
    let changeToToken = PassthroughSubject<SwapToken, Never>()
    let submitTransaction = PassthroughSubject<(PendingTransaction, String), Never>()
    let viewAppeared = PassthroughSubject<Void, Never>()
    let viewDisappeared = PassthroughSubject<Void, Never>()

    // MARK: - Params
    var fromTokenInputViewModel: SwapInputViewModel
    var toTokenInputViewModel: SwapInputViewModel
    
    @Published var initializingState: InitializingState = .loading
    @Published var arePricesLoading: Bool = false

    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false {
        didSet {
            swapToken()
        }
    }
    @Published var showFinished = false

    #if !RELEASE
    @Published var errorLogs: [String]?
    #endif

    let stateMachine: JupiterSwapStateMachine
    var currentState: JupiterSwapState { stateMachine.currentState }
    var continueUpdateOnDisappear = false // Special flag for update if view is disappeared

    private let preChosenWallet: Wallet?
    private var timer: Timer?
    private let source: JupiterSwapSource
    private var wasMinToastShown = false // Special flag not to show toast again if state has not changed

    init(
        stateMachine: JupiterSwapStateMachine,
        fromTokenInputViewModel: SwapInputViewModel,
        toTokenInputViewModel: SwapInputViewModel,
        source: JupiterSwapSource,
        preChosenWallet: Wallet? = nil
    ) {
        self.fromTokenInputViewModel = fromTokenInputViewModel
        self.toTokenInputViewModel = toTokenInputViewModel
        self.stateMachine = stateMachine
        self.preChosenWallet = preChosenWallet
        self.source = source
        super.init()
        bind()
        bindActions()
    }

    deinit {
        timer?.invalidate()
    }

    func update() async {
        await stateMachine.accept(
            action: .update
        )
    }

    func reset() {
        // This function resets inputs and logs after a successful swap
        fromTokenInputViewModel.amount = .zero
        isSliderOn = false
        showFinished = false
        cancelUpdate()
        #if !RELEASE
        errorLogs?.removeAll()
        #endif
    }

    #if !RELEASE
    func copyAndClearLogs() {
        let tokens = (getRouteInSymbols() ?? [])
            .compactMap { symbol -> SwapLogsInfo.TokenInfo? in
                guard let token = stateMachine.currentState.swapTokens
                    .first(where: {$0.token.symbol == symbol})
                else { return nil }
                
                return .init(
                    pubkey: token.userWallet?.pubkey,
                    balance: token.userWallet?.amount,
                    symbol: token.token.symbol,
                    mint: token.token.address
                )
            }
        
        let logsInfo = SwapLogsInfo(
            swapTransaction: currentState.swapTransaction,
            route: stateMachine.currentState.route,
            routeInSymbols: getRouteInSymbols()?.joined(separator: " -> "),
            amountFrom: stateMachine.currentState.amountFrom,
            amountTo: stateMachine.currentState.amountTo,
            tokens: tokens,
            errorLogs: errorLogs,
            fees: .init(
                networkFee: stateMachine.currentState.networkFee,
                accountCreationFee: stateMachine.currentState.accountCreationFee,
                liquidityFee: stateMachine.currentState.liquidityFee
            ),
            prices: stateMachine.currentState.tokensPriceMap
                .filter { (key, _) in
                    currentState.fromToken.token.address.contains(key) ||
                        currentState.toToken.token.address.contains(key)
                }
        )
        
        UIPasteboard.general.string = logsInfo.jsonString
        errorLogs = nil
        notificationService.showToast(title: "✅", text: "Logs copied to clipboard")
    }
    
    func getRouteInSymbols() -> [String]? {
        let tokensList = stateMachine.currentState.swapTokens.map(\.token)
        return stateMachine.currentState.route?.toSymbols(tokensList: tokensList)
    }
    #endif

    func scheduleUpdate() {
        cancelUpdate()
        timer = .scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task {
                await self?.update()
            }
        }
    }
}

private extension SwapViewModel {
    func bind() {
        // swap wallets status
        swapWalletsRepository.status
            .receive(on: DispatchQueue.main)
            .sinkAsync { [weak self] dataStatus in
                guard let self else { return }
                switch dataStatus {
                case .loading, .initial:
                    self.initializingState = .loading
                case let .ready(jupiterTokens, routeMap):
                    await self.initialize(jupiterTokens: jupiterTokens, routeMap: routeMap)
                case .failed:
                    self.initializingState = .failed
                }
                
            }
            .store(in: &subscriptions)
        
        // listen to state of the stateMachine
        stateMachine.statePublisher
            .receive(on: RunLoop.main)
            .sinkAsync { [weak self] updatedState in
                guard let self else { return }
                self.handle(state: updatedState)
                self.updateActionButton(for: updatedState)
                self.log(priceImpact: updatedState.priceImpact, value: updatedState.route?.priceImpactPct)
                self.log(from: updatedState.status)
            }
            .store(in: &subscriptions)
        
        // update user wallets only when initializingState is success
        Resolver.resolve(WalletsRepository.self)
            .dataPublisher
            .filter { [weak self] _ in self?.initializingState == .success }
            .removeDuplicates()
            .sinkAsync { [weak self] userWallets in
                await self?.stateMachine.accept(
                    action: .updateUserWallets(userWallets: userWallets)
                )
            }
            .store(in: &subscriptions)

        // update fromToken only when initializingState is success
        changeFromToken
            .filter { [weak self] _ in self?.initializingState == .success }
            .sinkAsync { [weak self] token in
                guard let self else { return }
                let newState = await self.stateMachine.accept(
                    action: .changeFromToken(token)
                )
                Defaults.fromTokenAddress = token.address
                self.logChangeToken(isFrom: true, token: token, amount: newState.amountFrom)
            }
            .store(in: &subscriptions)

        // update toToken only when initializingState is success
        changeToToken
            .filter { [weak self] _ in self?.initializingState == .success }
            .sinkAsync { [ weak self] token in
                guard let self else { return }
                let newState = await self.stateMachine.accept(
                    action: .changeToToken(token)
                )
                Defaults.toTokenAddress = token.address
                self.logChangeToken(isFrom: false, token: token, amount: newState.amountTo)
            }
            .store(in: &subscriptions)
    }

    func initialize(jupiterTokens: [Token], routeMap: RouteMap) async {
        let newState = await self.stateMachine
            .accept(
                action: .initialize(
                    account: userWalletManager.wallet?.account,
                    jupiterTokens: jupiterTokens,
                    routeMap: routeMap,
                    preChosenFromTokenMintAddress: preChosenWallet?.mintAddress ?? Defaults.fromTokenAddress,
                    preChosenToTokenMintAddress: Defaults.toTokenAddress
                )
            )
        logStart(from: newState.fromToken, to: newState.toToken)
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
        case .creatingSwapTransaction:
            arePricesLoading = false
        case .ready:
            arePricesLoading = false
        case .error:
            arePricesLoading = false
        }
    }

    func bindActions() {
        switchTokens
            .sinkAsync(receiveValue: { [weak self] _ in
                guard let self else { return }
                // cache the current amountTo
                let newAmountFrom = self.currentState.amountTo
                
                // switch from and to token
                let newState = await self.stateMachine.accept(
                    action: .switchFromAndToTokens
                )
                
                // change amountFrom into newAmountFrom
                // the changeAmountFrom action will be kicked
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.fromTokenInputViewModel.amount = newAmountFrom
                }
                
                // log
                self.logSwitch(from: newState.fromToken, to: newState.toToken)
            })
            .store(in: &subscriptions)

        tryAgain
            .sinkAsync { [weak self] _ in
                guard let self else { return }
                await self.swapWalletsRepository.load()
            }
            .store(in: &subscriptions)

        viewAppeared
            .sink { [weak self] in
                guard let self, self.initializingState == .success else { return }
                self.scheduleUpdate()
                self.continueUpdateOnDisappear = false //  Reset value
            }
            .store(in: &subscriptions)

        viewDisappeared
            .sink { [weak self] in
                guard let self, !self.continueUpdateOnDisappear else { return }
                self.cancelUpdate()
            }
            .store(in: &subscriptions)
    }

    func cancelUpdate() {
        timer?.invalidate()
    }

    func updateActionButton(for state: JupiterSwapState) {
        // assert that amount > 0
        guard let amount = state.amountFrom, amount > 0 else {
            actionButtonData = SliderActionButtonData.zero
            return
        }
        
        // observe status
        switch state.status {
        case .ready:
            if state.swapTransaction != nil {
                actionButtonData = SliderActionButtonData(
                    isEnabled: true,
                    title: L10n.swap(state.fromToken.token.symbol, state.toToken.token.symbol)
                )
            }
        case .requiredInitialize, .loadingTokenTo, .loadingAmountTo, .switching, .initializing, .creatingSwapTransaction:
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.counting)
        case .error(.notEnoughFromToken):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.notEnough(state.fromToken.token.symbol))
        case .error(.equalSwapTokens):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.youCanTSwapBetweenTheSameToken)
        case .error(.networkConnectionError):
            notificationService.showConnectionErrorNotification()
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.noInternetConnection)
        case .error(.inputTooHigh(let max)):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.max(max.toString(maximumFractionDigits: Int(state.fromToken.token.decimals))))
            if state.fromToken.address == Token.nativeSolana.address, !wasMinToastShown {
                notificationService.showToast(title: "✅", text: L10n.weLeftAMinimumSOLBalanceToSaveTheAccountAddress)
                wasMinToastShown = true
            }
        case .error(.createTransactionFailed):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.creatingTransactionFailed)
        case .error(.routeIsNotFound):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.noSwapOptionsForTheseTokens)
        case .error(.minimumAmount):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.enterGreaterValue)
        default:
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.somethingWentWrong)
        }

        guard wasMinToastShown else { return }
        switch state.status {
        case .error(.inputTooHigh), .loadingAmountTo:
            break
        default:
            wasMinToastShown = false
        }
    }

    private func swapToken() {
        guard isSliderOn,
              let account = currentState.account,
              let sourceWallet = currentState.fromToken.userWallet,
              let amountFrom = currentState.amountFrom,
              let amountTo = currentState.amountTo
        else {
            return
        }
        
        // cancel updating
        cancelUpdate()
        
        #if !RELEASE
        errorLogs = nil
        #endif
        
        // form transaction
        let destinationWallet = currentState.toToken.userWallet ?? Wallet(pubkey: nil, token: currentState.toToken.token)
        
        let swapTransaction = JupiterSwapTransaction(
            authority: account.publicKey.base58EncodedString,
            sourceWallet: sourceWallet,
            destinationWallet: destinationWallet,
            fromAmount: amountFrom,
            toAmount: amountTo,
            slippage: Double(stateMachine.currentState.slippageBps) / 100,
            metaInfo: SwapMetaInfo(
                swapMAX: false, // FIXME: - Swap max or not
                swapUSD: 0 // FIXME:
            ),
            payingFeeWallet: nil, // FIXME: - PayingFeeWallet
            feeAmount: .zero, // FIXME: - feeAmount
            execution: { [unowned self] in
                let transactionId = try await self.createSwapExecution(account: account)
                self.logSwapApprove(signature: transactionId)
                return transactionId
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
        submitTransaction.send((
            pendingTransaction,
            formattedSlippage
        ))
    }

    private func createSwapExecution(account: KeyPair) async throws -> String {
        do {
            // get route
            guard let route = currentState.route
            else {
                throw JupiterError.invalidResponse
            }
            
            // send to blockchain
            let transactionId = try await JupiterSwapBusinessLogic.sendToBlockchain(
                account: account,
                swapTransaction: currentState.swapTransaction,
                route: route,
                services: stateMachine.services
            )
            
            debugPrint("---transactionId: ", transactionId)
            isSliderOn = false
            return transactionId
        } catch let error as SolanaSwift.APIClientError {
            debugPrint("---errorSendingTransaction: ", error)
            switch error {
            case .responseError(let detail):
                #if !RELEASE
                errorLogs = detail.data?.logs
                #endif
            default:
                break
            }
            isSliderOn = false
            throw error
        } catch {
            debugPrint("---errorSendingTransaction: ", error)
            isSliderOn = false
            throw error
        }
    }
}

private extension SwapViewModel {
    var formattedSlippage: String {
        let slippage = Double(stateMachine.currentState.slippageBps) / 100
        var slippageString = String(format: "%.2f", slippage)
        while slippageString.last == "0" {
            slippageString.removeLast()
        }
        return slippageString + "%"
    }
}

// MARK: - Analytics
extension SwapViewModel {
    func logSettingsClick() {
        analyticsManager.log(event: .swapSettingsClick)
    }

    func logReturnFromChangeToken(isFrom: Bool) {
        analyticsManager.log(event: isFrom ? .swapReturnFromChangingTokenA : .swapReturnFromChangingTokenB)
    }

    func logTransactionProgressOpened() {
        analyticsManager.log(event: .swapTransactionProgressScreen)
    }

    func logTransactionProgressDone() {
        analyticsManager.log(event: .swapTransactionProgressScreenDone)
    }

    func logTransaction(error: Error?) {
        if let error, error.isSlippageError {
            analyticsManager.log(event: .swapErrorSlippage)
        } else {
            analyticsManager.log(event: .swapErrorDefault(isBlockchainRelated: error is SolanaError))
        }
    }

    private func logSwapApprove(signature: String) {
        guard let amountFrom = currentState.amountFrom else { return }
        analyticsManager.log(event: .swapClickApproveButtonNew(tokenA: currentState.fromToken.token.symbol, tokenB: currentState.toToken.token.symbol, swapSum: amountFrom, swapUSD: currentState.amountFromFiat, signature: signature))
    }

    private func log(from status: JupiterSwapState.Status) {
        switch status {
        case .error(.notEnoughFromToken):
            analyticsManager.log(event: .swapErrorTokenAInsufficientAmount)
        case .error(.routeIsNotFound):
            analyticsManager.log(event: .swapErrorTokenPairNotExist)
        default:
            break
        }
    }

    private func logStart(from: SwapToken, to: SwapToken) {
        analyticsManager.log(event: .swapStartScreenNew(lastScreen: source.rawValue, from: from.token.symbol, to: to.token.symbol))
    }

    private func logSwitch(from: SwapToken, to: SwapToken) {
        analyticsManager.log(event: .swapSwitchTokens(tokenAName: from.token.symbol, tokenBName: to.token.symbol))
    }

    private func log(priceImpact: JupiterSwapState.SwapPriceImpact?, value: Decimal?) {
        guard let priceImpact, let value else { return }
        switch priceImpact {
        case .medium:
            analyticsManager.log(event: .swapPriceImpactLow(priceImpact: value))
        case .high:
            analyticsManager.log(event: .swapPriceImpactHigh(priceImpact: value))
        }
    }

    private func logChangeToken(isFrom: Bool, token: SwapToken, amount: Double?) {
        guard let amount else { return }
        if isFrom {
            analyticsManager.log(event: .swapChangingTokenA(tokenAName: token.token.symbol, tokenAValue: amount))
        } else {
            analyticsManager.log(event: .swapChangingTokenB(tokenBName: token.token.symbol, tokenBValue: amount))
        }
    }
}
