import Jupiter
import FeeRelayerSwift
import SolanaSwift

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
        case createTransactionFailed
    }

    enum Status: Equatable {
        case requiredInitialize
        case initializing
        case loadingAmountTo
        case loadingTokenTo
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
    var status: Status

    /// User account to create a transaction
    var account: KeyPair?

    /// Available routes for every token mint
    var routeMap: RouteMap
    
    /// Current token prices map
    var tokensPriceMap: [String: Double]
    
    /// Pre-selected route
    var route: Route?

    /// Current swap transaction for the state
    var swapTransaction: String?

    /// All available routes for current tokens pair
    var routes: [Route]
    
    /// Info of all swappable tokens
    var swapTokens: [SwapToken]

    /// Token that user's swapping from
    var fromToken: SwapToken
    
    /// Amount from
    var amountFrom: Double?

    /// Token that user's swapping to
    var toToken: SwapToken
    
    /// Amount to
    var amountTo: Double?
    
    /// SlippageBps is slippage multiplied by 100 (be careful)
    var slippageBps: Int
    
    /// FeeRelayer's relay context
    var relayContext: RelayContext?
    
    // MARK: - Computed properties
    
    /// All the wallets that user owns
    var userWallets: [Wallet] {
        swapTokens.compactMap(\.userWallet)
    }
    
    var amountFromFiat: Double {
        priceInfo.fromPrice * amountFrom
    }
    
    var amountToFiat: Double {
        priceInfo.toPrice * amountTo
    }
    
    /// Price info between from token and to token
    var priceInfo: SwapPriceInfo {
        SwapPriceInfo(
            fromPrice: tokensPriceMap[fromToken.address] ?? 0,
            toPrice: tokensPriceMap[toToken.address] ?? 0,
            relation: amountTo > 0 ? amountFrom/amountTo: 0
        )
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
    
    /// Network fee of the transaction, can be modified by the fee relayer service
    var networkFee: SwapFeeInfo? {
        // FIXME: - Relay context and free transaction
        guard let signatureFee = route?.fees?.signatureFee
        else { return nil }
        
        // FIXME: - paying fee token
        let payingFeeToken = Token.nativeSolana
        
        let networkFeeAmount = signatureFee
            .convertToBalance(decimals: payingFeeToken.decimals)
        
        return SwapFeeInfo(
            amount: networkFeeAmount,
            tokenSymbol: payingFeeToken.symbol,
            tokenName: payingFeeToken.name,
            amountInFiat: tokensPriceMap[payingFeeToken.address] * networkFeeAmount,
            pct: nil,
            canBePaidByKeyApp: true
        )
    }
    
    var accountCreationFee: SwapFeeInfo? {
        // FIXME: - Relay context and relay account
        guard let route,
              let fees = route.fees
        else { return nil }
        
        // FIXME: - paying fee token
        let payingFeeToken = Token.nativeSolana
        
        let accountCreationFee = (fees.openOrdersDeposits + fees.ataDeposits).reduce(0, +)
            .convertToBalance(decimals: payingFeeToken.decimals)
        return SwapFeeInfo(
            amount: accountCreationFee,
            tokenSymbol: payingFeeToken.symbol,
            tokenName: payingFeeToken.symbol,
            amountInFiat: tokensPriceMap[payingFeeToken.address] * accountCreationFee,
            pct: nil,
            canBePaidByKeyApp: false
        )
    }
    
    var liquidityFee: [SwapFeeInfo] {
        guard let route else { return [] }
        return route.marketInfos.map(\.lpFee)
            .compactMap { lqFee -> SwapFeeInfo? in
                guard let token = swapTokens.map(\.token).first(where: { $0.address == lqFee.mint }),
                      let amount = UInt64(lqFee.amount)?.convertToBalance(decimals: token.decimals)
                else {
                    return nil
                }
                
                return SwapFeeInfo(
                    amount: amount,
                    tokenSymbol: token.symbol,
                    tokenName: token.name,
                    amountInFiat: tokensPriceMap[token.address] * amount,
                    pct: lqFee.pct,
                    canBePaidByKeyApp: false
                )
            }
    }
    
    var exchangeRateInfo: String? {
        // price from jupiter
        let rate: Double?
        if priceInfo.relation != 0 {
            rate = priceInfo.relation
        }
        
        // price from coingecko
        else if let fromPrice = tokensPriceMap[fromToken.token.address],
                let toPrice = tokensPriceMap[toToken.token.address],
                fromPrice != 0
        {
            rate = toPrice / fromPrice
        }
        
        // otherwise
        else {
            rate = nil
        }
        
        guard let rate else { return nil }
        
        let onetoToken = 1.tokenAmountFormattedString(symbol: toToken.token.symbol, maximumFractionDigits: Int(toToken.token.decimals), roundingMode: .down)
        let amountFromToken = rate.tokenAmountFormattedString(symbol: fromToken.token.symbol, maximumFractionDigits: Int(fromToken.token.decimals), roundingMode: .down)
        return [onetoToken, amountFromToken].joined(separator: " ≈ ")
    }
    
    // MARK: - Initializing state

    static var zero: Self {
        Self.init(
            status: .requiredInitialize,
            routeMap: RouteMap(mintKeys: [], indexesRouteMap: [:]),
            tokensPriceMap: [:],
            route: nil,
            routes: [],
            swapTokens: [],
            fromToken: .nativeSolana,
            toToken: .nativeSolana,
            slippageBps: 0,
            relayContext: nil
        )
    }
    
    // MARK: - Modified function
    
    func error(_ reason: ErrorReason) -> Self {
        var state = self
        state.status = .error(reason: reason)
        return state
    }

    func modified(_ modify: (inout Self) -> Void) -> Self {
        var state = self
        modify(&state)
        return state
    }
}

extension JupiterSwapState {
    var isTransactionCanBeCreated: Bool {
        return amountTo > 0 && status == .ready
    }
}
