import Jupiter
import SolanaSwift
import Resolver
import Combine
import KeyAppBusiness

extension JupiterSwapBusinessLogic {
    static func initializeAction(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        account: KeyPair?,
        jupiterTokens: [Token],
        routeMap: RouteMap,
        preChosenFromTokenMintAddress: String?,
        preChosenToTokenMintAddress: String?
    ) async -> JupiterSwapState {
        // get swapTokens, pricesMap
        let (swapTokens, tokensPriceMap) = await (
            getSwapTokens(jupiterTokens),
            getTokensPriceMap()
        )
        
        // choose fromToken
        let fromToken = getFromToken(
            preChosenFromTokenMintAddress: preChosenFromTokenMintAddress,
            swapTokens: swapTokens
        )
        
        // auto choose toToken
        let toToken = getToToken(
            preChosenToTokenMintAddress: preChosenToTokenMintAddress,
            swapTokens: swapTokens,
            fromToken: fromToken
        )
        
        // state
        return JupiterSwapState.zero.modified {
            $0.status = .ready
            $0.account = account
            $0.tokensPriceMap = tokensPriceMap
            $0.routeMap = routeMap
            $0.swapTokens = swapTokens
            $0.slippageBps = Int(0.5 * 100)
            $0.fromToken = fromToken
            $0.toToken = toToken
        }
    }
    
    // MARK: - Helpers

    private static func getSwapTokens(
        _ jupiterTokens: [Token]
    ) async -> [SwapToken] {
        // wait for wallets repository to be loaded and get wallets
        let solanaAccountsService = Resolver.resolve(SolanaAccountsService.self)
        
        // This function will never throw an error (Publisher of ErrorType == Never)
        let wallets = (try? await Publishers.CombineLatest(
            solanaAccountsService.fetcherStatePublisher,
            solanaAccountsService.accountsPublisher
        )
            .filter { (state, _) in
                  state == .loaded
            }
            .map { _, wallets in
                return wallets
            }
            .eraseToAnyPublisher()
            .async()) ?? []
        
        // map userWallets with jupiter tokens
        return jupiterTokens
            .map { jupiterToken in
            
            // if userWallet found
            if let userWallet = wallets.first(where: { $0.mintAddress == jupiterToken.address }) {
                return SwapToken(token: userWallet.token, userWallet: userWallet)
            }
            
            // otherwise return jupiter token with no userWallet
            return SwapToken(token: jupiterToken, userWallet: nil)
        }
    }
    
    private static func getTokensPriceMap() async -> [String: Double] {
        return await Resolver.resolve(PricesStorage.self).retrievePrices()
            .reduce([String: Double]()) { combined, element in
                guard let value = element.value.value else { return combined }
                var combined = combined
                combined[element.key] = value
                return combined
            }
    }
    
    private static func getFromToken(
        preChosenFromTokenMintAddress: String?,
        swapTokens: [SwapToken]
    ) -> SwapToken {
        // map preChosenToken
        let preChosenFromToken: SwapToken?
        if let fromTokenAddress = preChosenFromTokenMintAddress {
            preChosenFromToken = swapTokens.first(where: { $0.address == fromTokenAddress })
        } else {
            preChosenFromToken = nil
        }
        
        return preChosenFromToken ??
            autoChoose(swapTokens: swapTokens)?.fromToken ??
            SwapToken(token: .usdc, userWallet: nil)
    }
    
    private static func getToToken(
        preChosenToTokenMintAddress: String?,
        swapTokens: [SwapToken],
        fromToken: SwapToken
    ) -> SwapToken {
        // map preChosenToken
        let preChosenToToken: SwapToken?
        if let toTokenAddress = preChosenToTokenMintAddress {
            preChosenToToken = swapTokens.first(where: { $0.address == toTokenAddress })
        } else {
            preChosenToToken = nil
        }
        
        // auto choose fromToken
        return preChosenToToken ??
            autoChooseToToken(for: fromToken, from: swapTokens) ??
            SwapToken(token: .nativeSolana, userWallet: nil)
    }
}
