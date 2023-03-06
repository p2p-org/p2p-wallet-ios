import Jupiter
import FeeRelayerSwift

struct JupiterSwapState: Equatable {
    // MARK: - Nested type
    
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

    // MARK: - Properties

    /// Status of current state
    let status: Status

    /// Available routes for every token mint
    let routeMap: RouteMap
    
    /// Pre-selected route
    let route: Route?
    
    /// All available routes for current tokens pair
    let routes: [Route]
    
    /// Info of all swappable tokens
    let swapTokens: [SwapToken]
    
    /// Price info between from token and to token
    let priceInfo: SwapPriceInfo

    /// Token that user's swapping from
    let fromToken: SwapToken

    /// Token that user's swapping to
    let toToken: SwapToken
    
    /// SlippageBps is slippage multiplied by 100 (be careful)
    let slippageBps: Int
    
    /// FeeRelayer's relay context
    let relayContext: RelayContext

    /// Network fee of the transaction, can be modified by the fee relayer service
    var networkFee: SwapFeeInfo
    
    // MARK: - Computed properties
    
    var amountFrom: Double {
        guard let route, let amountFrom = UInt64(route.inAmount) else { return 0 }
        return amountFrom.convertToBalance(decimals: fromToken.token.decimals)
    }
    
    var amountFromFiat: Double {
        priceInfo.fromPrice * amountFrom
    }
    
    var amountTo: Double {
        guard let route, let amountTo = UInt64(route.outAmount) else { return 0 }
        return amountTo.convertToBalance(decimals: toToken.token.decimals)
    }
    
    var amountToFiat: Double {
        priceInfo.toPrice * amountTo
    }
    
    var priceImpact: SwapPriceImpact? {
        switch route?.priceImpactPct {
        case let val where val >= 0.01 && val < 0.03:
            return .medium
        case let val where val >= 0.03:
            return .high
        default:
            return nil
        }
    }

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
    
    var possibleToTokens: [SwapToken] {
        let toAddresses = Set(routeMap.indexesRouteMap[fromToken.address] ?? [])
        return swapTokens.filter { toAddresses.contains($0.token.address) }
    }
    
    var accountCreationFee: SwapFeeInfo {
        let nonCreatedTokenMints = route.marketInfos.map(\.outputMint)
            .compactMap { mint in
                swapTokens.first(where: { $0.token.address == mint && $0.userWallet == nil })?.address
            }
        
        let accountCreationFeeAmount = (context.minimumTokenAccountBalance * UInt64(nonCreatedTokenMints.count))
            .convertToBalance(decimals: Token.nativeSolana.decimals)
        let accountCreationFee = SwapFeeInfo(
            amount: accountCreationFeeAmount,
            tokenSymbol: "SOL",
            tokenName: "Solana",
            amountInFiat: solanaPrice * accountCreationFeeAmount,
            pct: nil,
            canBePaidByKeyApp: false
        )
    }
    
    var liquidityFee: [SwapFeeInfo] {
        guard let route else { return [] }
        return route.marketInfos.map(\.lpFee)
            .compactMap { lqFee -> SwapFeeInfo? in
                guard let token = state.swapTokens.map(\.token).first(where: { $0.address == lqFee.mint }),
                      let amount = UInt64(lqFee.amount)?.convertToBalance(decimals: token.decimals)
                else {
                    return nil
                }
                
                let price = priceService.getCurrentPrice(for: token.address)
                
                return SwapFeeInfo(
                    amount: amount,
                    tokenSymbol: token.symbol,
                    tokenName: token.name,
                    amountInFiat: price * amount,
                    pct: lqFee.pct,
                    canBePaidByKeyApp: false
                )
            }
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
}
