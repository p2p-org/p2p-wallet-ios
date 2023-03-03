import Jupiter
import SolanaSwift
import Resolver

extension JupiterSwapBusinessLogic {
    static func calculateAmounts(state: JupiterSwapState, services: JupiterSwapServices) async -> JupiterSwapState {
        guard state.fromToken.address != state.toToken.address else {
            return state.copy(status: .error(reason: .equalSwapTokens))
        }

        guard state.amountFrom > 0 else {
            return state.copy(
                status: .ready,
                amountFrom: 0,
                amountFromFiat: 0,
                amountTo: 0,
                amountToFiat: 0
            )
        }

        let amountFromLamports = state.amountFrom.toLamport(decimals: state.fromToken.token.decimals)

        do {
            let data = try await services.jupiterClient.quote(
                inputMint: state.fromToken.address,
                outputMint: state.toToken.address,
                amount: String(amountFromLamports),
                swapMode: nil,
                slippageBps: state.slippage,
                feeBps: nil,
                onlyDirectRoutes: nil,
                userPublicKey: nil,
                enforceSingleTx: nil
            )
            
            // routes
            let routes = data.data
            
            // if pre chosen route is stil available, choose it
            // if not choose the first one
            guard let route = data.data.first(
                where: {$0.id == state.route?.id})
                    ?? data.data.first,
                let toAmountLamports = Lamports(route.outAmount)
            else {
                return state.copy(status: .error(reason: .routeIsNotFound), amountTo: 0, amountToFiat: 0)
            }

            // to amount
            let amountTo = toAmountLamports.convertToBalance(decimals: state.toToken.token.decimals)
            let newPriceInfo = SwapPriceInfo(
                fromPrice: state.priceInfo.fromPrice,
                toPrice: state.priceInfo.toPrice,
                relation: Double(state.amountFrom/amountTo)
            )

            // price impact
            let priceImpact: JupiterSwapState.SwapPriceImpact?
            switch route.priceImpactPct {
            case let val where val >= 0.01 && val < 0.03:
                priceImpact = .medium
            case let val where val >= 0.03:
                priceImpact = .high
            default:
                priceImpact = nil
            }
            
            // get fee relayer context
            let context = try await services.relayContextManager.getCurrentContextOrUpdate()
    
            // FIXME: - network fee with fee relayer, Temporarily paying with SOL
            let priceService = Resolver.resolve(PricesService.self)
            let solanaPrice = priceService.getCurrentPrice(for: Token.nativeSolana.address)
            
            let networkFeeAmount = context.lamportsPerSignature
                .convertToBalance(decimals: Token.nativeSolana.decimals)
            let networkFee = SwapFeeInfo(
                amount: networkFeeAmount,
                token: "SOL",
                amountInFiat: solanaPrice * networkFeeAmount,
                canBePaidByKeyApp: true
            )
            
            // FIXME: - account creation fee with fee relayer, Temporarily paying with SOL
            let nonCreatedTokenMints = route.marketInfos.map(\.outputMint)
                .compactMap { mint in
                    state.swapTokens.first(where: { $0.token.address == mint && $0.userWallet == nil })?.address
                }
            
            let accountCreationFeeAmount = (context.minimumTokenAccountBalance * UInt64(nonCreatedTokenMints.count))
                .convertToBalance(decimals: Token.nativeSolana.decimals)
            let accountCreationFee = SwapFeeInfo(
                amount: accountCreationFeeAmount,
                token: "SOL",
                amountInFiat: solanaPrice * accountCreationFeeAmount,
                canBePaidByKeyApp: false
            )
            
            // Liquidity fees
            let liquidityFees = route.marketInfos.map(\.lpFee)
                .compactMap { lqFee -> SwapFeeInfo? in
                    guard let token = state.swapTokens.map(\.token).first(where: { $0.address == lqFee.mint }),
                          let amount = UInt64(lqFee.amount)?.convertToBalance(decimals: token.decimals)
                    else {
                        return nil
                    }
                    
                    let price = priceService.getCurrentPrice(for: token.address)
                    
                    return SwapFeeInfo(
                        amount: amount,
                        token: token.symbol,
                        amountInFiat: price * amount,
                        canBePaidByKeyApp: false
                    )
                }

            return await validateAmounts(
                state: state.copy(
                    status: .ready,
                    amountTo: amountTo,
                    amountToFiat: amountTo * newPriceInfo.toPrice,
                    priceInfo: newPriceInfo,
                    route: route,
                    routes: routes,
                    priceImpact: priceImpact,
                    networkFee: networkFee,
                    accountCreationFee: accountCreationFee,
                    liquidityFee: liquidityFees
                ),
                services: services
            )
        }
        catch let error {
            return handle(error: error, for: state)
        }
    }

    private static func handle(error: Error, for state: JupiterSwapState) -> JupiterSwapState {
        if (error as NSError).isNetworkConnectionError {
            return state.copy(status: .error(reason: .networkConnectionError))
        }
        return state.copy(status: .error(reason: .routeIsNotFound))
    }

    private static func validateAmounts(state: JupiterSwapState, services: JupiterSwapServices) async -> JupiterSwapState {
        let status: JupiterSwapState.Status

        if let balance = state.fromToken.userWallet?.amount {
            if state.amountFrom > balance {
                status = .error(reason: .notEnoughFromToken)
            } else if state.fromToken.address == Token.nativeSolana.address {
                status = await validateNativeSOL(balance: balance, state: state, services: services)
            } else {
                status = .ready
            }
        } else {
            status = .error(reason: .notEnoughFromToken)
        }

        return state.copy(status: status, route: state.route, priceImpact: state.priceImpact)
    }

    private static func validateNativeSOL(balance: Double, state: JupiterSwapState, services: JupiterSwapServices) async -> JupiterSwapState.Status {
        do {
            let decimals = state.fromToken.token.decimals
            let minBalance = try await services.relayContextManager.getCurrentContextOrUpdate().minimumRelayAccountBalance
            let remains = (balance - state.amountFrom).toLamport(decimals: decimals)
            if remains > 0 && remains < minBalance {
                let maximumInput = (balance.toLamport(decimals: decimals) - minBalance).convertToBalance(decimals: decimals)
                return .error(reason: .inputTooHigh(maximumInput))
            } else {
                return .ready
            }
        } catch {
            return .error(reason: .networkConnectionError)
        }
    }
}
