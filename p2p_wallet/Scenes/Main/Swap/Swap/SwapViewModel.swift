import AnalyticsManager
import Combine
import Foundation
import Jupiter
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Task_retrying
import UIKit

final class SwapViewModel: BaseViewModel, ObservableObject {
    enum ViewState {
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
    @Injected private var walletsRepository: SolanaAccountsService

    // MARK: - Actions

    let switchTokens = PassthroughSubject<Void, Never>()
    let tryAgain = PassthroughSubject<Void, Never>()
    let changeFromToken = PassthroughSubject<SwapToken, Never>()
    let changeToToken = PassthroughSubject<SwapToken, Never>()
    let submitTransaction = PassthroughSubject<(PendingTransaction, String), Never>()

    // TODO: - Refactor, ViewModel shouldn't keep subViewModels
    var fromTokenInputViewModel: SwapInputViewModel
    var toTokenInputViewModel: SwapInputViewModel

    // MARK: - To View

    @Published var viewState: ViewState = .loading
    @Published var arePricesLoading: Bool = false

    @Published var actionButtonData = SliderActionButtonData.zero
    @Published var isSliderOn = false {
        didSet {
            swapToken()
        }
    }

    @Published var showFinished = false
    @Published var warningState: SwapPriceImpactView.Model?
    @Published var isViewAppeared = false

    #if !RELEASE
        @Published var errorLogs: [String]?
    #endif

    let stateMachine: JupiterSwapStateMachine
    var currentState: JupiterSwapState { stateMachine.currentState }
    var continueUpdateOnDisappear = false // Special flag for update if view is disappeared

    private let preChosenWallet: SolanaAccount?
    private let destinationWallet: SolanaAccount?
    private var timer: Timer?
    private let source: JupiterSwapSource
    private var wasMinToastShown = false // Special flag not to show toast again if state has not changed

    // MARK: - Init

    init(
        stateMachine: JupiterSwapStateMachine,
        fromTokenInputViewModel: SwapInputViewModel,
        toTokenInputViewModel: SwapInputViewModel,
        source: JupiterSwapSource,
        preChosenWallet: SolanaAccount? = nil,
        destinationWallet: SolanaAccount? = nil
    ) {
        self.fromTokenInputViewModel = fromTokenInputViewModel
        self.toTokenInputViewModel = toTokenInputViewModel
        self.stateMachine = stateMachine
        self.preChosenWallet = preChosenWallet
        self.destinationWallet = destinationWallet
        self.source = source
        super.init()
        bind()
        bindActions()
    }

    deinit {
        timer?.invalidate()
    }

    func update() async {
        guard stateMachine.currentState.swapTransaction != nil else { return }
        // Update only if swap transaction is created
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
                        .first(where: { $0.token.symbol == symbol })
                    else { return nil }

                    return .init(
                        pubkey: token.userWallet?.address,
                        balance: token.userWallet?.amount,
                        symbol: token.token.symbol,
                        mint: token.token.mintAddress
                    )
                }

            let logsInfo = SwapLogsInfo(
                swapTransaction: currentState.swapTransaction?.stringValue,
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
                    .filter { key, _ in
                        currentState.fromToken.token.mintAddress.contains(key) ||
                            currentState.toToken.token.mintAddress.contains(key)
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
        timer = .scheduledTimer(withTimeInterval: Defaults.swapRouteRefeshRate ?? 20, repeats: true) { [weak self] _ in
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
                    self.viewState = .loading
                case let .ready(jupiterTokens, routeMap):
                    await self.initialize(jupiterTokens: jupiterTokens, routeMap: routeMap)
                case .failed:
                    self.viewState = .failed
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
                self.updateWarningMessage(for: updatedState)
                self.log(amountFrom: updatedState.amountFrom, from: updatedState.status)
            }
            .store(in: &subscriptions)

        walletsRepository
            .statePublisher
            .removeDuplicates { $0.value == $1.value }
            .filter { [weak self] _ in
                // update user wallets only when initializingState is success
                self?.viewState == .success
            }
            .sinkAsync { [weak self] userWallets in
                await self?.stateMachine.accept(
                    action: .updateUserWallets(userWallets: userWallets.value)
                )
            }
            .store(in: &subscriptions)

        // update fromToken only when viewState is success
        changeFromToken
            .filter { [weak self] _ in self?.viewState == .success }
            .sinkAsync { [weak self] token in
                guard let self else { return }
                self.logChangeToken(isFrom: true, token: token)
                await self.stateMachine.accept(
                    action: .changeFromToken(token)
                )
                self.fromTokenInputViewModel.amount = nil // Reset previously set amount with new from token
                Defaults.fromTokenAddress = token.mintAddress
            }
            .store(in: &subscriptions)

        // update toToken only when viewState is success
        changeToToken
            .filter { [weak self] _ in self?.viewState == .success }
            .sinkAsync { [weak self] token in
                guard let self else { return }
                self.logChangeToken(isFrom: false, token: token)
                let newState = await self.stateMachine.accept(
                    action: .changeToToken(token)
                )
                Defaults.toTokenAddress = token.mintAddress
                self.log(priceImpact: newState.priceImpact, value: newState.route?.priceImpactPct)
            }
            .store(in: &subscriptions)
    }

    func initialize(jupiterTokens: [TokenMetadata], routeMap: RouteMap) async {
        let newState = await stateMachine
            .accept(
                action: .initialize(
                    account: userWalletManager.wallet?.account,
                    jupiterTokens: jupiterTokens,
                    routeMap: routeMap,
                    preChosenFromTokenMintAddress: preChosenWallet?.mintAddress ?? Defaults.fromTokenAddress,
                    preChosenToTokenMintAddress: destinationWallet?.mintAddress ?? Defaults.toTokenAddress
                )
            )
        if source != .tapMain {
            // Tap main has own logic of calling this method. See 'logStartFromMain'
            logStart(from: newState.fromToken, to: newState.toToken)
        }
    }

    func handle(state: JupiterSwapState) {
        switch state.status {
        case .requiredInitialize, .initializing:
            viewState = .loading
        case .error(.initializationFailed), .error(reason: .networkConnectionError):
            viewState = .failed
        default:
            viewState = .success
        }

        switch state.status {
        case .requiredInitialize, .initializing, .loadingTokenTo, .loadingAmountTo, .switching:
            arePricesLoading = true
        case let .creatingSwapTransaction(isSumalationEnabled):
            // We need to show loading if simulation is happening
            arePricesLoading = isSumalationEnabled
        case .ready:
            arePricesLoading = false
        case .error:
            arePricesLoading = false
        }
    }

    func bindActions() {
        switchTokens
            .filter { [weak self] _ in self?.viewState == .success }
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
                switch self.currentState.status {
                case .error(reason: .initializationFailed):
                    await self.swapWalletsRepository.load()
                case let .error(reason: .networkConnectionError(action)):
                    await self.stateMachine.accept(action: .retry(action))
                default:
                    break
                }
            }
            .store(in: &subscriptions)

        $isViewAppeared
            .filter { [weak self] _ in self?.viewState == .success }
            .sink { [weak self] isAppeared in
                guard let self else { return }
                if isAppeared {
                    self.scheduleUpdate()
                    self.continueUpdateOnDisappear = false //  Reset value
                } else if !self.continueUpdateOnDisappear {
                    self.cancelUpdate()
                }
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
        case .requiredInitialize, .loadingTokenTo, .loadingAmountTo, .switching, .initializing,
             .creatingSwapTransaction:
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.counting)
        case .error(.notEnoughFromToken):
            actionButtonData = SliderActionButtonData(
                isEnabled: false,
                title: L10n.notEnough(state.fromToken.token.symbol)
            )
        case .error(.equalSwapTokens):
            actionButtonData = SliderActionButtonData(isEnabled: false, title: L10n.youCanTSwapBetweenTheSameToken)
        case let .error(.inputTooHigh(max)):
            actionButtonData = SliderActionButtonData(
                isEnabled: false,
                title: L10n.max(max.toString(maximumFractionDigits: Int(state.fromToken.token.decimals)))
            )
            if state.fromToken.mintAddress == TokenMetadata.nativeSolana.mintAddress, !wasMinToastShown {
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

    func updateWarningMessage(for state: JupiterSwapState) {
        switch state.status {
        case .ready, .requiredInitialize, .loadingTokenTo, .loadingAmountTo,
             .switching, .initializing, .creatingSwapTransaction:
            break
        case .error:
            warningState = nil
            return
        }

        let slippage = Double(state.slippageBps) / 100
        if let priceImpact = state.priceImpact {
            let warningMessage = L10n
                .ThePriceIsHigherBecauseOfYourTradeSize
                .considerSplittingYourTransactionIntoMultipleSwaps
            warningState = SwapPriceImpactView.Model(title: warningMessage, impact: priceImpact)
        } else if let route = state.route,
                  let keyAppFee = Double(route.keyapp?.fee ?? ""),
                  let outAmount = Double(route.outAmount),
                  (keyAppFee / (outAmount + keyAppFee)) > slippage
        {
            let warningMessage = L10n
                .theFeeIsMoreThanTheDefinedSlippageDueToOneTimeAccountCreationFeeBySolanaBlockchain(
                    "\(slippage.toString().replacingOccurrences(of: ".", with: ","))%"
                )
            warningState = SwapPriceImpactView.Model(title: warningMessage, impact: .medium)
        } else {
            warningState = nil
        }
    }

    func swapToken() {
        guard isSliderOn,
              let account = currentState.account,
              let sourceWallet = currentState.fromToken.userWallet,
              let amountFrom = currentState.amountFrom,
              let amountTo = currentState.amountTo,
              let route = currentState.route
        else {
            return
        }

        // cancel updating
        cancelUpdate()

        #if !RELEASE
            errorLogs = nil
        #endif

        if let swapTransaction = currentState.swapTransaction {
            logSwapApprove(signature: swapTransaction.stringValue)
        }

        // form transaction
        let destinationWallet = currentState.toToken.userWallet ?? SolanaAccount(
            pubkey: nil,
            token: currentState.toToken.token
        )

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
            route: route,
            account: account,
            swapTransaction: currentState.swapTransaction,
            services: stateMachine.services
        )

        // delegate work to transaction handler
        let transactionIndex = transactionHandler.sendTransaction(
            swapTransaction
        )

        // return pending transaction
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

        // Observe transaction and update status
        transactionHandler.observeTransaction(transactionIndex: transactionIndex)
            .compactMap { $0 }
            .filter(\.isConfirmedOrError)
            .prefix(1)
            .receive(on: RunLoop.main)
            .sink { [weak self] tx in
                guard let self else { return }

                // error state
                if let error = tx.status.error {
                    switch error {
                    case let SolanaSwift.APIClientError.responseError(detail):
                        #if !RELEASE
                            self.errorLogs = detail.data?.logs
                        #endif
                    default:
                        break
                    }

                    // log error
                    self.logTransaction(error: error)
                }

                // release slider
                self.isSliderOn = false
            }
            .store(in: &subscriptions)
    }
}

private extension SwapViewModel {
    var formattedSlippage: String {
        let slippage = Double(stateMachine.currentState.slippageBps) / 100
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        let slippageString = formatter
            .string(from: NSNumber(floatLiteral: slippage)) ?? String(format: "%.2f", slippage)
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
            analyticsManager
                .log(event: .swapErrorDefault(isBlockchainRelated: error?.isSolanaBlockchainRelatedError ?? false))
        }
    }

    func logStartFromMain() {
        logStart(from: currentState.fromToken, to: currentState.toToken)
    }

    private func logSwapApprove(signature: String) {
        guard let amountFrom = currentState.amountFrom else { return }
        analyticsManager.log(event: .swapClickApproveButtonNew(
            tokenA: currentState.fromToken.token.symbol,
            tokenB: currentState.toToken.token.symbol,
            swapSum: amountFrom,
            swapUSD: currentState.amountFromFiat,
            signature: signature
        ))
    }

    private func log(amountFrom: Double?, from status: JupiterSwapState.Status) {
        guard amountFrom > 0 else { return }
        // Do not log anything if amountFrom is not set
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
        analyticsManager
            .log(event: .swapStartScreenNew(lastScreen: source.rawValue, from: from.token.symbol, to: to.token.symbol))
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

    private func logChangeToken(isFrom: Bool, token: SwapToken) {
        let amount = token.userWallet?.amount ?? 0
        if isFrom {
            analyticsManager.log(event: .swapChangingTokenA(tokenAName: token.token.symbol, tokenAValue: amount))
        } else {
            analyticsManager.log(event: .swapChangingTokenB(tokenBName: token.token.symbol, tokenBValue: amount))
        }
    }
}

private extension Error {
    var isSolanaBlockchainRelatedError: Bool {
        guard let error = ((self as? APIClientError) ?? // APIClientError
            ((self as? TaskRetryingError)?.lastError as? APIClientError)) // Retrying with last error
        else {
            return false
        }
        switch error {
        case .responseError:
            return true
        default:
            return false
        }
    }
}
