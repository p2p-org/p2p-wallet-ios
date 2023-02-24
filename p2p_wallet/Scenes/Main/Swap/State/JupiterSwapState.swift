import Jupiter

struct JupiterSwapState: Equatable {
    enum ErrorReason: Equatable, Error {
        case initializationFailed
        case networkConnectionError

        case notEnoughFromToken
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

    let status: Status

    let routeMap: RouteMap
    let swapTokens: [SwapToken]

    let amountFrom: Double
    let amountFromFiat: Double
    let amountTo: Double

    let fromToken: SwapToken
    let toToken: SwapToken
    let possibleToTokens: [SwapToken]
    let priceInfo: SwapPriceInfo

    let slippage: Int
    let route: Route?

    init(
        status: Status,
        routeMap: RouteMap,
        swapTokens: [SwapToken],
        amountFrom: Double,
        amountFromFiat: Double,
        amountTo: Double,
        fromToken: SwapToken,
        toToken: SwapToken,
        possibleToTokens: [SwapToken],
        priceInfo: SwapPriceInfo,
        slippage: Int,
        route: Route? = nil
    ) {
        self.status = status
        self.routeMap = routeMap
        self.swapTokens = swapTokens
        self.amountFrom = amountFrom
        self.amountFromFiat = amountFromFiat
        self.amountTo = amountTo
        self.fromToken = fromToken
        self.toToken = toToken
        self.possibleToTokens = possibleToTokens
        self.priceInfo = priceInfo
        self.slippage = slippage
        self.route = route
    }

    static func zero(
        status: Status = .requiredInitialize,
        routeMap: RouteMap = RouteMap(mintKeys: [], indexesRouteMap: [:]),
        swapTokens: [SwapToken] = [],
        amountFrom: Double = .zero,
        amountFromFiat: Double = .zero,
        amountTo: Double = .zero,
        fromToken: SwapToken = .nativeSolana,
        toToken: SwapToken = .nativeSolana,
        possibleToTokens: [SwapToken] = [],
        priceInfo: SwapPriceInfo = SwapPriceInfo(fromPrice: .zero, toPrice: .zero),
        slippage: Int = 0,
        route: Route? = nil
    ) -> JupiterSwapState {
        JupiterSwapState(
            status: status,
            routeMap: routeMap,
            swapTokens: swapTokens,
            amountFrom: amountFrom,
            amountFromFiat: amountFromFiat,
            amountTo: amountTo,
            fromToken: fromToken,
            toToken: toToken,
            possibleToTokens: possibleToTokens,
            priceInfo: priceInfo,
            slippage: slippage,
            route: route
        )
    }

    func copy(
        status: Status? = nil,
        routeMap: RouteMap? = nil,
        swapTokens: [SwapToken]? = nil,
        amountFrom: Double? = nil,
        amountFromFiat: Double? = nil,
        amountTo: Double? = nil,
        fromToken: SwapToken? = nil,
        toToken: SwapToken? = nil,
        possibleToTokens: [SwapToken]? = nil,
        priceInfo: SwapPriceInfo? = nil,
        slippage: Int? = nil,
        route: Route? = nil
    ) -> JupiterSwapState {
        JupiterSwapState(
            status: status ?? self.status,
            routeMap: routeMap ?? self.routeMap,
            swapTokens: swapTokens ?? self.swapTokens,
            amountFrom: amountFrom ?? self.amountFrom,
            amountFromFiat: amountFromFiat ?? self.amountFromFiat,
            amountTo: amountTo ?? self.amountTo,
            fromToken: fromToken ?? self.fromToken,
            toToken: toToken ?? self.toToken,
            possibleToTokens: possibleToTokens ?? self.possibleToTokens,
            priceInfo: priceInfo ?? self.priceInfo,
            slippage: slippage ?? self.slippage,
            route: route ?? self.route
        )
    }
}
