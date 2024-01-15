import Combine
import Jupiter
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func initializeAction(
        state _: JupiterSwapState,
        services: JupiterSwapServices,
        account: KeyPair?,
        jupiterTokens: [TokenMetadata],
        routeMap: RouteMap,
        preChosenFromTokenMintAddress: String?,
        preChosenToTokenMintAddress: String?
    ) async -> JupiterSwapState {
        // get swapTokens, pricesMap
        async let swapTokens = getSwapTokens(jupiterTokens)
        async let pricesMap = getTokensPriceMap()
        async let lamportPerSignature = getLamportPerSignature(solanaAPIClient: services.solanaAPIClient)
        async let splAccountCreationFee = try? services.solanaAPIClient.getMinimumBalanceForRentExemption(
            dataLength: SPLTokenAccountState.BUFFER_LENGTH,
            commitment: nil
        )

        let (swapTokensResult, priceMapResult, lamportPerSignatureResult, splAccountCreationFeeResult) = await (
            swapTokens,
            pricesMap,
            lamportPerSignature,
            splAccountCreationFee
        )

        // choose fromToken
        let fromToken = await getFromToken(
            preChosenFromTokenMintAddress: preChosenFromTokenMintAddress,
            swapTokens: swapTokens
        )

        // auto choose toToken
        let toToken = await getToToken(
            preChosenFromTokenMintAddress: preChosenFromTokenMintAddress,
            preChosenToTokenMintAddress: preChosenToTokenMintAddress,
            swapTokens: swapTokens,
            fromToken: fromToken
        )

        // state
        return JupiterSwapState.zero.modified {
            $0.status = .ready
            $0.account = account
            $0.tokensPriceMap = priceMapResult
            $0.routeMap = routeMap
            $0.swapTokens = swapTokensResult
            $0.slippageBps = Int(0.5 * 100)
            $0.fromToken = fromToken
            $0.toToken = toToken
            $0.lamportPerSignature = lamportPerSignatureResult
            $0.splAccountCreationFee = splAccountCreationFeeResult ?? 0
        }
    }

    // MARK: - Helpers

    private static func getSwapTokens(
        _ jupiterTokens: [TokenMetadata]
    ) async -> [SwapToken] {
        // wait for wallets repository to be loaded and get wallets
        let walletsRepository = Resolver.resolve(SolanaAccountsService.self)

        // This function will never throw an error (Publisher of ErrorType == Never)
        let wallets = (
            try? await walletsRepository
                .statePublisher
                .filter { state in
                    state.status == .ready
                }
                .map { state in
                    state.value
                }
                .eraseToAnyPublisher()
                .async()
        ) ?? []

        // map userWallets with jupiter tokens
        return jupiterTokens
            .map { jupiterToken in

                // if userWallet found
                if let userWallet = wallets.first(where: { $0.mintAddress == jupiterToken.mintAddress }) {
                    // move tags
                    var token = userWallet.token
                    token.tags = jupiterToken.tags
                    return SwapToken(token: token, userWallet: userWallet)
                }

                // otherwise return jupiter token with no userWallet
                return SwapToken(token: jupiterToken, userWallet: nil)
            }
    }

    private static func getTokensPriceMap() async -> [String: Double] {
        do {
            let accounts = Resolver.resolve(SolanaAccountsService.self).state.value
            let prices = try await Resolver.resolve(PriceService.self)
                .getPrices(tokens: accounts.map(\.token), fiat: Defaults.fiat.rawValue)

            return Dictionary(prices.map { ($0.key.address, $0.value.doubleValue) }) { lhs, _ in lhs }
        } catch {
            return [:]
        }
    }

    private static func getLamportPerSignature(solanaAPIClient: SolanaAPIClient) async -> Lamports {
        do {
            let fees = try await solanaAPIClient.getFees(commitment: nil)
            return fees.feeCalculator?.lamportsPerSignature ?? 5000
        } catch {
            return 5000
        }
    }

    private static func getFromToken(
        preChosenFromTokenMintAddress: String?,
        swapTokens: [SwapToken]
    ) -> SwapToken {
        // map preChosenToken
        let preChosenFromToken: SwapToken?
        if let fromTokenAddress = preChosenFromTokenMintAddress {
            preChosenFromToken = swapTokens.first(where: { $0.mintAddress == fromTokenAddress })
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
            let toToken = swapTokens.first(where: { $0.mintAddress == address })
        {
            return toToken
        }

        // 2. Search for toToken if fromToken is preChosen
        if
            preChosenFromTokenMintAddress != nil,
            let toToken = autoChooseToToken(for: fromToken, from: swapTokens)
        {
            return toToken
        }

        // 3. Auto choose toToken if none is preset
        return autoChoose(swapTokens: swapTokens)?.toToken ?? SwapToken.nativeSolana
    }
}
