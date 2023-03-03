import Jupiter

struct JupiterSwapState: Equatable {
    enum ErrorReason: Equatable {
        case initializationFailed
        case networkConnectionError

        case notEnoughFromToken
        case inputTooHigh(Double)
        case equalSwapTokens

        case unknown
        case coingeckoPriceFailure
        case routeIsNotFound
    }

    enum Status: Equatable {
        case requiredInitialize
        case initializing
        case loadingAmountTo
        case loadingTokenTo
        case quoteLoading
        case switching
        case ready
        case error(reason: ErrorReason)
    }

    enum SwapPriceImpact {
        case medium
        case high
    }

    let status: Status

    let routeMap: RouteMap
    let swapTokens: [SwapToken]

    let amountFrom: Double
    let amountFromFiat: Double
    let amountTo: Double
    let amountToFiat: Double

    let fromToken: SwapToken
    let toToken: SwapToken
    let possibleToTokens: [SwapToken]
    let priceInfo: SwapPriceInfo
    
    /// SlippageBps is slippage multiplied by 100 (be careful)
    let slippageBps: Int
    let route: Route?
    let routes: [Route]
    let priceImpact: SwapPriceImpact?
    
    var networkFee: SwapFeeInfo
    var accountCreationFee: SwapFeeInfo
    var liquidityFee: [SwapFeeInfo]

    init(
        status: Status,
        routeMap: RouteMap,
        swapTokens: [SwapToken],
        amountFrom: Double,
        amountFromFiat: Double,
        amountTo: Double,
        amountToFiat: Double,
        fromToken: SwapToken,
        toToken: SwapToken,
        possibleToTokens: [SwapToken],
        priceInfo: SwapPriceInfo,
        slippageBps: Int,
        route: Route? = nil,
        routes: [Route] = [],
        priceImpact: SwapPriceImpact? = nil,
        networkFee: SwapFeeInfo = .init(amount: 0, token: nil, amountInFiat: nil, canBePaidByKeyApp: true),
        accountCreationFee: SwapFeeInfo = .init(amount: 0, token: nil, amountInFiat: nil, canBePaidByKeyApp: false),
        liquidityFee: [SwapFeeInfo] = []
    ) {
        self.status = status
        self.routeMap = routeMap
        self.swapTokens = swapTokens
        self.amountFrom = amountFrom
        self.amountFromFiat = amountFromFiat
        self.amountTo = amountTo
        self.amountToFiat = amountToFiat
        self.fromToken = fromToken
        self.toToken = toToken
        self.possibleToTokens = possibleToTokens
        self.priceInfo = priceInfo
        self.slippageBps = slippageBps
        self.route = route
        self.routes = routes
        self.priceImpact = priceImpact
        self.networkFee = networkFee
        self.accountCreationFee = accountCreationFee
        self.liquidityFee = liquidityFee
    }

    static func zero(
        status: Status = .requiredInitialize,
        routeMap: RouteMap = RouteMap(mintKeys: [], indexesRouteMap: [:]),
        swapTokens: [SwapToken] = [],
        amountFrom: Double = .zero,
        amountFromFiat: Double = .zero,
        amountTo: Double = .zero,
        amountToFiat: Double = .zero,
        fromToken: SwapToken = .nativeSolana,
        toToken: SwapToken = .nativeSolana,
        possibleToTokens: [SwapToken] = [],
        priceInfo: SwapPriceInfo = SwapPriceInfo(fromPrice: .zero, toPrice: .zero),
        slippageBps: Int = 0,
        route: Route? = nil,
        routes: [Route] = [],
        priceImpact: SwapPriceImpact? = nil
    ) -> JupiterSwapState {
        JupiterSwapState(
            status: status,
            routeMap: routeMap,
            swapTokens: swapTokens,
            amountFrom: amountFrom,
            amountFromFiat: amountFromFiat,
            amountTo: amountTo,
            amountToFiat: amountToFiat,
            fromToken: fromToken,
            toToken: toToken,
            possibleToTokens: possibleToTokens,
            priceInfo: priceInfo,
            slippageBps: slippageBps,
            route: route,
            routes: routes,
            priceImpact: priceImpact
        )
    }

    func copy(
        status: Status? = nil,
        routeMap: RouteMap? = nil,
        swapTokens: [SwapToken]? = nil,
        amountFrom: Double? = nil,
        amountFromFiat: Double? = nil,
        amountTo: Double? = nil,
        amountToFiat: Double? = nil,
        fromToken: SwapToken? = nil,
        toToken: SwapToken? = nil,
        possibleToTokens: [SwapToken]? = nil,
        priceInfo: SwapPriceInfo? = nil,
        slippageBps: Int? = nil,
        route: Route? = nil,
        routes: [Route]? = nil,
        priceImpact: SwapPriceImpact? = nil,
        networkFee: SwapFeeInfo? = nil,
        accountCreationFee: SwapFeeInfo? = nil,
        liquidityFee: [SwapFeeInfo]? = nil
    ) -> JupiterSwapState {
        JupiterSwapState(
            status: status ?? self.status,
            routeMap: routeMap ?? self.routeMap,
            swapTokens: swapTokens ?? self.swapTokens,
            amountFrom: amountFrom ?? self.amountFrom,
            amountFromFiat: amountFromFiat ?? self.amountFromFiat,
            amountTo: amountTo ?? self.amountTo,
            amountToFiat: amountToFiat ?? self.amountToFiat,
            fromToken: fromToken ?? self.fromToken,
            toToken: toToken ?? self.toToken,
            possibleToTokens: possibleToTokens ?? self.possibleToTokens,
            priceInfo: priceInfo ?? self.priceInfo,
            slippageBps: slippageBps ?? self.slippageBps,
            route: route ?? self.route,
            routes: routes ?? self.routes,
            priceImpact: priceImpact ?? self.priceImpact,
            networkFee: networkFee ?? self.networkFee,
            accountCreationFee: accountCreationFee ?? self.accountCreationFee,
            liquidityFee: liquidityFee ?? self.liquidityFee
        )
    }
    
    // MARK: - Getters

    var bestOutAmount: UInt64 {
        routes.map(\.outAmount).compactMap(UInt64.init).max() ?? 0
    }
    
    var minimumReceivedAmount: Double? {
        guard let outAmountString = route?.outAmount,
              let outAmount = UInt64(outAmountString)
        else {
            return nil
        }
        let slippage = Double(slippageBps) / 100
        return outAmount.convertToBalance(decimals: toToken.token.decimals) * (1 - slippage)
    }
}
