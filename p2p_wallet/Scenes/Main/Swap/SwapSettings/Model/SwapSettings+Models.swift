//
import Foundation
import Jupiter

struct SwapSettingsRouteInfo: Identifiable, Equatable {
    init(id: String = UUID().uuidString, name: String, description: String, tokensChain: String) {
        self.id = id
        self.name = name
        self.description = description
        self.tokensChain = tokensChain
    }

    let id: String
    let name: String
    let description: String
    let tokensChain: String
}

struct JupiterSwapStateInfo: Equatable {
    let routes: [SwapSettingsRouteInfo]
    var currentRoute: SwapSettingsRouteInfo?
    let networkFee: SwapFeeInfo
    let accountCreationFee: SwapFeeInfo?
    let liquidityFee: [SwapFeeInfo]
    let platformFee: PlatformFee?
    let platformFeeAmount: SwapFeeInfo?
    let minimumReceived: SwapTokenAmountInfo?
    let transferFee: String?
    let transferFeeFiat: Double?
    let exchangeRateInfo: String?

    var estimatedFees: String? {
        var fees = (liquidityFee + [networkFee, accountCreationFee, platformFeeAmount]
            .compactMap { $0 })
            .compactMap(\.amountInFiat)
            .reduce(0.0, +)
        if let transferFeeFiat {
            fees = fees + transferFeeFiat
        }

        return fees > 0 ? "≈ " + fees.formattedFiat() : nil
    }
}

// MARK: - Extensions

extension QuoteResponse {
    func mapToInfo(
        currentState: JupiterSwapState
    ) -> SwapSettingsRouteInfo {
        .init(
            id: id,
            name: name,
            description: priceDescription(
                bestOutAmount: currentState.bestOutAmount,
                toTokenDecimals: currentState.toToken.token.decimals,
                toTokenSymbol: currentState.toToken.token.symbol
            ) ?? "",
            tokensChain: chainDescription(tokensList: currentState.swapTokens.map(\.token))
        )
    }
}

extension JupiterSwapState {
    var info: JupiterSwapStateInfo {
        .init(
            routes: routes.map {
                $0.mapToInfo(currentState: self)
            },
            currentRoute: route?
                .mapToInfo(currentState: self),
            networkFee: networkFee ?? SwapFeeInfo(
                amount: 0,
                canBePaidByKeyApp: true
            ),
            accountCreationFee: accountCreationFee,
            liquidityFee: liquidityFee,
            platformFee: route?.platformFee,
            platformFeeAmount: platformFeeAmount,
            minimumReceived: minimumReceivedAmount == nil ? nil : .init(
                amount: minimumReceivedAmount!,
                token: toToken.token.symbol
            ),
            transferFee: transferFeeBasisPoints != nil ? "\(Double(transferFeeBasisPoints!) / 100)%" : nil,
            transferFeeFiat: transferFeeBasisPoints != nil ? Double(transferFeeBasisPoints!) / 1000 * amountFromFiat :
                nil,
            exchangeRateInfo: exchangeRateInfo
        )
    }

    var isSettingsLoading: Bool {
        // observe stateMachine status
        switch status {
        case .requiredInitialize, .initializing, .loadingAmountTo, .loadingTokenTo, .switching:
            return true
        case .ready, .creatingSwapTransaction:
            return false
        case .error:
            return false
        }
    }
}
