import FeeRelayerSwift
import Foundation
import Jupiter
import KeyAppKitCore
import SolanaSwift

struct JupiterSwapState: Equatable {
    // MARK: - Nested type

    enum RetryAction: Equatable {
        case createTransaction(isSimulationOn: Bool)
        case gettingRoute
    }

    enum ErrorReason: Equatable {
        case initializationFailed
        case networkConnectionError(RetryAction)

        case notEnoughFromToken
        case inputTooHigh(Double)
        case equalSwapTokens

        case routeIsNotFound
        case createTransactionFailed
        case minimumAmount
    }

    enum Status: Equatable {
        case requiredInitialize
        case initializing
        case loadingAmountTo
        case loadingTokenTo
        case switching
        case creatingSwapTransaction(isSimulationOn: Bool)
        case ready
        case error(reason: ErrorReason)

        var hasError: Bool {
            switch self {
            case .error:
                return true
            default:
                return false
            }
        }
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

    /// Selected route
    var route: QuoteResponse?

    /// Current swap transaction for the state
    var swapTransaction: SwapTransaction?

    /// All available routes for current tokens pair
    var routes: [QuoteResponse]

    /// Info of all swappable tokens
    var swapTokens: [SwapToken]

    /// Token that user's swapping from
    var fromToken: SwapToken

    /// Amount from
    var amountFrom: Double?

    /// Token that user's swapping to
    var toToken: SwapToken

    /// SlippageBps is slippage multiplied by 100 (be careful)
    var slippageBps: Int

    /// Lamport per signature
    var lamportPerSignature: Lamports

    /// Fee for creating spl token account. This field will be used for calculating when user connects direct to
    /// jupiter.
    var splAccountCreationFee: Lamports

    // MARK: - Computed properties

    /// Amount to
    var amountTo: Double? {
        guard let route else {
            return nil
        }
        return UInt64(route.outAmount)?
            .convertToBalance(decimals: toToken.token.decimals)
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
            fromPrice: tokensPriceMap[fromToken.mintAddress] ?? 0,
            toPrice: tokensPriceMap[toToken.mintAddress] ?? 0,
            relation: amountTo > 0 ? amountFrom / amountTo : 0
        )
    }

    var priceImpact: SwapPriceImpact? {
        guard let value = route?.priceImpactPct else { return nil }
        switch value {
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
        let slippage = Double(slippageBps) / 100 / 100
        return outAmount.convertToBalance(decimals: toToken.token.decimals) * (1 - slippage)
    }

    // TODO(jupiter): Fetch dynamic in future.
    var possibleToTokens: [SwapToken] {
        swapTokens
    }

    /// Network fee of the transaction, can be modified by the fee relayer service
    var networkFee: SwapFeeInfo? {
        guard route != nil else { return nil }

        if let keyapp = route?.keyapp {
            // Fee is calculated on P2P backend
            let payingFeeToken = TokenMetadata.nativeSolana
            let networkFeeAmount = keyapp.fees.signatureFee.convertToBalance(decimals: payingFeeToken.decimals)

            return SwapFeeInfo(
                amount: networkFeeAmount,
                tokenSymbol: payingFeeToken.symbol,
                tokenName: payingFeeToken.name,
                tokenPriceInCurrentFiat: tokensPriceMap[payingFeeToken.mintAddress],
                pct: nil,
                canBePaidByKeyApp: true
            )
        } else {
            var signatureFee: Lamports = 0

            if
                let swapTransaction = swapTransaction?.stringValue,
                let base64Data = Data(base64Encoded: swapTransaction, options: .ignoreUnknownCharacters),
                let versionedTransaction = try? VersionedTransaction.deserialize(data: base64Data)
            {
                signatureFee = UInt64(versionedTransaction.message.value.header.numRequiredSignatures) *
                    lamportPerSignature
            }

            let payingFeeToken = TokenMetadata.nativeSolana
            let networkFeeAmount = signatureFee
                .convertToBalance(decimals: payingFeeToken.decimals)

            return SwapFeeInfo(
                amount: networkFeeAmount,
                tokenSymbol: payingFeeToken.symbol,
                tokenName: payingFeeToken.name,
                tokenPriceInCurrentFiat: tokensPriceMap[payingFeeToken.mintAddress],
                pct: nil,
                canBePaidByKeyApp: true
            )
        }
    }

    var accountCreationFee: SwapFeeInfo? {
        guard route != nil else { return nil }

        if let keyapp = route?.keyapp {
            let accountCreationFeeInSOL = keyapp.fees.totalFeeAndDeposits
                .convertToBalance(decimals: TokenMetadata.nativeSolana.decimals)

            // prepare for converting
            let payingFeeToken: TokenMetadata
            let accountCreationFee: Double

            // convert to toToken
            if let tokenPrice = tokensPriceMap[toToken.mintAddress],
               tokenPrice > 0
            {
                payingFeeToken = toToken.token
                accountCreationFee =
                    ((tokensPriceMap[TokenMetadata.nativeSolana.mintAddress] / tokenPrice) *
                        accountCreationFeeInSOL)
                    .rounded(decimals: payingFeeToken.decimals)
            } else {
                // fallback to SOL
                payingFeeToken = TokenMetadata.nativeSolana
                accountCreationFee = accountCreationFeeInSOL
            }
            return SwapFeeInfo(
                amount: accountCreationFee,
                tokenSymbol: payingFeeToken.symbol,
                tokenName: payingFeeToken.name,
                tokenPriceInCurrentFiat: tokensPriceMap[payingFeeToken.mintAddress],
                pct: nil,
                canBePaidByKeyApp: false
            )

        } else {
            // get route & fees
            guard route != nil else { return nil }

            let amount: Lamports
            if toToken.userWallet == nil {
                amount = splAccountCreationFee
            } else {
                amount = 0
            }

            return SwapFeeInfo(
                amount: amount.convertToBalance(decimals: TokenMetadata.nativeSolana.decimals),
                tokenSymbol: "SOL",
                tokenName: "Solana",
                tokenPriceInCurrentFiat: tokensPriceMap[TokenMetadata.nativeSolana.mintAddress],
                canBePaidByKeyApp: false
            )
        }
    }

    var liquidityFee: [SwapFeeInfo] {
        guard let route else { return [] }
        return route.routePlan
            .map { ($0.swapInfo.feeAmount, $0.swapInfo.feeMint) }
            .compactMap { feeAmount, feeMint -> SwapFeeInfo? in
                guard let token = swapTokens.map(\.token).first(where: { $0.mintAddress == feeMint }),
                      let amount = UInt64(feeAmount)?.convertToBalance(decimals: token.decimals)
                else {
                    return nil
                }

                return SwapFeeInfo(
                    amount: amount,
                    tokenSymbol: token.symbol,
                    tokenName: token.name,
                    tokenPriceInCurrentFiat: tokensPriceMap[token.mintAddress],
                    // TODO(jupiter): Pct in v6 is not provided for each route plan. We have summarize value in response.
                    pct: 0,
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
        else if let fromPrice = tokensPriceMap[fromToken.token.mintAddress],
                let toPrice = tokensPriceMap[toToken.token.mintAddress],
                fromPrice != 0
        {
            rate = toPrice / fromPrice
        }

        // otherwise
        else {
            rate = nil
        }

        guard let rate else { return nil }

        let onetoToken = 1.tokenAmountFormattedString(
            symbol: toToken.token.symbol,
            maximumFractionDigits: Int(toToken.token.decimals),
            roundingMode: .down
        )
        let amountFromToken = rate.tokenAmountFormattedString(
            symbol: fromToken.token.symbol,
            maximumFractionDigits: Int(fromToken.token.decimals),
            roundingMode: .down
        )
        return [onetoToken, amountFromToken].joined(separator: " ≈ ")
    }

    // MARK: - Initializing state

    static var zero: Self {
        Self(
            status: .requiredInitialize,
            routeMap: RouteMap(mintKeys: [], indexesRouteMap: [:]),
            tokensPriceMap: [:],
            route: nil,
            routes: [],
            swapTokens: [],
            fromToken: .nativeSolana,
            toToken: .nativeSolana,
            slippageBps: 0,
            lamportPerSignature: 5000,
            splAccountCreationFee: 0
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
