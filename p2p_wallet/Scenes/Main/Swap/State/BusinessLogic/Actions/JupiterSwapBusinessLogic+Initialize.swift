import Jupiter
import SolanaSwift
import Resolver
import Combine

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
            preChosenFromTokenMintAddress: preChosenFromTokenMintAddress,
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
        let walletsRepository = Resolver.resolve(WalletsRepository.self)
        
        // This function will never throw an error (Publisher of ErrorType == Never)
        let wallets = (try? await Publishers.CombineLatest(
            walletsRepository.statePublisher,
            walletsRepository.dataPublisher
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
        preChosenFromTokenMintAddress: String?,
        preChosenToTokenMintAddress: String?,
        swapTokens: [SwapToken],
        fromToken: SwapToken
    ) -> SwapToken {

        // 1. Search for preChosen toToken if it exists
        if
            let address = preChosenToTokenMintAddress,
            let toToken = swapTokens.first(where: { $0.address == address }) {
            return toToken
        }

        // 2. Search for toToken if fromToken is preChosen
        if
            preChosenFromTokenMintAddress != nil,
            let toToken =  autoChooseToToken(for: fromToken, from: swapTokens) {
            return toToken
        }

        // 3. Auto choose toToken if none is preset
        return  autoChoose(swapTokens: swapTokens)?.toToken ?? SwapToken.nativeSolana
    }
}
