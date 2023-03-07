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
    @Injected private var transactionHandler: TransactionHandler
    @Injected private var userWalletManager: UserWalletManager

    // MARK: - Actions
    let switchTokens = PassthroughSubject<Void, Never>()
    let tryAgain = PassthroughSubject<Void, Never>()
    let changeFromToken = PassthroughSubject<SwapToken, Never>()
    let changeToToken = PassthroughSubject<SwapToken, Never>()
    let submitTransaction = PassthroughSubject<(PendingTransaction, String), Never>()

    // MARK: - Params
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
    
    private let preChosenWallet: Wallet?
    private var timer: Timer?

    init(preChosenWallet: Wallet? = nil) {
        stateMachine = JupiterSwapStateMachine(
            initialState: .zero,
            services: JupiterSwapServices(
                jupiterClient: JupiterRestClientAPI(version: .v4),
                pricesAPI: Resolver.resolve(),
                solanaAPIClient: Resolver.resolve(),
                relayContextManager: Resolver.resolve()
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
        await stateMachine.accept(action: .update)
    }

    #if !RELEASE
    func copyAndClearLogs() {
        var text = #"{"swapTransaction": "\#(currentState.swapTransaction ?? "")""#
        if let route = stateMachine.currentState.route?.jsonString {
            text += #", "route": \#(route)"#
            text += #", "routeInSymbols": "\#(getRouteInSymbols()?.joined(separator: " -> ") ?? "")""#
        }
        text += #", "amountFrom": "\#(stateMachine.currentState.amountFrom)""#
        text += #", "amountTo": "\#(stateMachine.currentState.amountTo)""#
        
        if let interTokens = getRouteInSymbols() {
            text += #", "tokens": ["#
            for (index, interToken) in interTokens.enumerated() {
                if index > 0 {
                    text += ", "
                }
                
                let token = stateMachine.currentState.swapTokens.first(where: {$0.token.symbol == interToken})
                
                text += #"{"pubkey": "\#(token?.userWallet?.pubkey ?? "null")", "balance": "\#(token?.userWallet?.amount ?? 0)", "symbol": "\#(token?.token.symbol ?? "")", "mint": "\#(token?.token.address ?? "")"}"#
            }
            text += #"]"#
        }
        
        if let errorLogs = errorLogs?.map({"\"\($0)\""}).joined(separator: ",") {
            text += #", "errorLogs": [\#(errorLogs)]"#
        }
        
        text += "}"
        UIPasteboard.general.string = text
        errorLogs = nil
        notificationService.showToast(title: "✅", text: "Logs copied to clipboard")
    }
    
    func getRouteInSymbols() -> [String]? {
        let tokensList = stateMachine.currentState.swapTokens.map(\.token)
        return stateMachine.currentState.route?.toSymbols(tokensList: tokensList)
    }
    #endif
}

private extension SwapViewModel {
    func bind() {
        // swap wallets status
        swapWalletsRepository.status
            .sinkAsync { [weak self] dataStatus in
                guard let self else { return }
                switch dataStatus {
                case .loading, .initial:
                    self.initializingState = .loading
                case let .ready(swapTokens, routeMap):
                    await self.initialize(swapTokens: swapTokens, routeMap: routeMap)
                case .failed:
                    self.initializingState = .failed
                }
                
            }
            .store(in: &subscriptions)
        
        // listen to state of the stateMachine
        stateMachine.statePublisher
            .sinkAsync { [weak self] updatedState in
                guard let self else { return }
                self.handle(state: updatedState)
                self.updateActionButton(for: updatedState)
            }
            .store(in: &subscriptions)
        
        // update user wallets only when initializingState is success
        Resolver.resolve(WalletsRepository.self)
            .dataPublisher
            .filter { [weak self] _ in self?.initializingState == .success }
            .removeDuplicates()
            .sinkAsync { [weak self] userWallets in
                await self?.stateMachine.accept(action: .updateUserWallets(userWallets: userWallets))
            }
            .store(in: &subscriptions)

        // update fromToken only when initializingState is success
        changeFromToken
            .filter { [weak self] _ in self?.initializingState == .success }
            .sinkAsync { [weak self] token in
                let newState = await self?.stateMachine.accept(action: .changeFromToken(token))
                Defaults.fromTokenAddress = token.address
                if newState?.isTransactionCanBeCreated == true {
                    let _ = await self?.stateMachine.accept(action: .createTransaction)
                }
            }
            .store(in: &subscriptions)

        // update toToken only when initializingState is success
        changeToToken
            .filter { [weak self] _ in self?.initializingState == .success }
            .sinkAsync { [ weak self] token in
                let newState = await self?.stateMachine.accept(action: .changeToToken(token))
                Defaults.toTokenAddress = token.address
                if newState?.isTransactionCanBeCreated == true {
                    let _ = await self?.stateMachine.accept(action: .createTransaction)
                }
            }
            .store(in: &subscriptions)
    }

    func initialize(swapTokens: [SwapToken], routeMap: RouteMap) async {
        var prechosenFromToken: SwapToken?
        var prechosenToToken: SwapToken?
        if let fromTokenAddress = self.preChosenWallet?.mintAddress ?? Defaults.fromTokenAddress {
            prechosenFromToken = swapTokens.first(where: { $0.address == fromTokenAddress })
        }
        if let toTokenAddress = Defaults.toTokenAddress {
            prechosenToToken = swapTokens.first(where: { $0.address == toTokenAddress })
        }
        let _ = await self.stateMachine
            .accept(action: .initialize(
                account: userWalletManager.wallet?.account,
                swapTokens: swapTokens,
                routeMap: routeMap,
                fromToken: prechosenFromToken,
                toToken: prechosenToToken
            ))
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
            actionButtonData = SliderActionButtonData(
                isEnabled: true,
                title: L10n.swap(state.fromToken.token.symbol, state.toToken.token.symbol)
            )
        default:
            arePricesLoading = false
        }
    }

    func bindActions() {
        switchTokens
            .sinkAsync(receiveValue: { [weak self] _ in
                guard let self else { return }
                await self.stateMachine.accept(
                    action: .switchFromAndToTokens
                )
            })
            .store(in: &subscriptions)

        tryAgain
            .sinkAsync { [weak self] _ in
                guard let self else { return }
                if self.currentState.swapTokens.isEmpty {
                    await self.swapWalletsRepository.load()
                } else {
                    await self.initialize(swapTokens: self.currentState.swapTokens, routeMap: self.currentState.routeMap)
                }
            }
            .store(in: &subscriptions)
    }

    func scheduleUpdate() {
        cancelUpdate()
        timer = .scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task {
                await self?.update()
            }
        }
    }

    func cancelUpdate() {
        timer?.invalidate()
    }

    func updateActionButton(for state: JupiterSwapState) {
        switch state.status {
        case .ready:
            if state.amountFrom == 0 {
                actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.enterTheAmount)
            }
        case .requiredInitialize, .loadingTokenTo, .loadingAmountTo, .switching, .initializing, .loadingTransaction:
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.counting)
        case .error(.notEnoughFromToken):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.notEnough(state.fromToken.token.symbol))
        case .error(.equalSwapTokens):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.youCanTSwapSameToken)
        case .error(.networkConnectionError):
            notificationService.showConnectionErrorNotification()
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.swapOfTheseTokensIsnTPossible)
        case .error(.inputTooHigh(let max)):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.max(max.toString(maximumFractionDigits: Int(state.fromToken.token.decimals))))
            if state.fromToken.address == Token.nativeSolana.address {
                notificationService.showToast(title: "✅", text: L10n.weLeftAMinimumSOLBalanceToSaveTheAccountAddress)
            }
        default:
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.swapOfTheseTokensIsnTPossible)
        }
    }

    private func swapToken() {
        guard isSliderOn,
              let account = currentState.account,
              let sourceWallet = currentState.fromToken.userWallet
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
            amountFrom: currentState.amountFrom,
            amountTo: currentState.amountTo,
            sourceWallet: sourceWallet,
            destinationWallet: destinationWallet,
            fromAmount: currentState.amountFrom,
            toAmount: currentState.amountTo,
            slippage: Double(stateMachine.currentState.slippageBps) / 100,
            metaInfo: SwapMetaInfo(
                swapMAX: false, // FIXME: - Swap max or not
                swapUSD: 0 // FIXME:
            ),
            payingFeeWallet: nil, // FIXME: - PayingFeeWallet
            feeAmount: .zero, // FIXME: - feeAmount
            execution: { [unowned self] in
                try await createSwapExecution(account: account)
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
            guard let swapTransaction = currentState.swapTransaction,
                  let base64Data = Data(base64Encoded: swapTransaction, options: .ignoreUnknownCharacters),
                  let versionedTransaction = try? VersionedTransaction.deserialize(data: base64Data)
            else {
                throw JupiterError.invalidResponse
            }

            let transactionId = try await JupiterSwapBusinessLogic.sendToBlockchain(
                account: account,
                versionedTransaction: versionedTransaction,
                solanaAPIClient: stateMachine.services.solanaAPIClient
            )
            debugPrint("---transactionId: ", transactionId)
            isSliderOn = false
            return transactionId
        } catch let error as SolanaSwift.APIClientError {
            debugPrint("---errorSendingTransaction: ", error)
            switch error {
            case .responseError(let detail):
                errorLogs = detail.data?.logs
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
