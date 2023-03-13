//
//  SwapSettingsViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 28.02.2023.
//

import Combine
import Resolver
import AnalyticsManager

protocol SwapSettingsViewModelIO: AnyObject {
    var rowTapped: AnyPublisher<SwapSettingsView.RowIdentifier, Never> { get }
}

final class SwapSettingsViewModel: BaseViewModel, ObservableObject {
    
    // Dependencies
    @Injected private var analyticsManager: AnalyticsManager
    
    // Properties
    @Published var status: Status
    @Published var slippage: Double?
    
    var info: Info? {
        status.info
    }

    // Subjects
    private let rowTappedSubject = PassthroughSubject<SwapSettingsView.RowIdentifier, Never>()
    
    // MARK: - Initializer
    
    init(
        status: Status,
        slippage: Double,
        swapStatePublisher: AnyPublisher<JupiterSwapState, Never>
    ) {
        self.status = status
        self.slippage = slippage
        super.init()
        bind(swapStatePublisher: swapStatePublisher)
    }

    private func bind(swapStatePublisher: AnyPublisher<JupiterSwapState, Never>) {
        swapStatePublisher
            .map { state -> SwapSettingsViewModel.Status in
                switch state.status {
                case .ready:
                    guard let route = state.route else { return .empty }
                    return .loaded(
                        .init(
                            routes: state.routes.map {.init(
                                id: $0.id,
                                name: $0.name,
                                description: $0.priceDescription(bestOutAmount: state.bestOutAmount, toTokenDecimals: state.toToken.token.decimals, toTokenSymbol: state.toToken.token.symbol) ?? "",
                                tokensChain: $0.chainDescription(tokensList: state.swapTokens.map(\.token))
                            )},
                            currentRoute: .init(
                                id: route.id,
                                name: route.name,
                                description: route.priceDescription(
                                    bestOutAmount: state.bestOutAmount,
                                    toTokenDecimals: state.toToken.token.decimals,
                                    toTokenSymbol: state.toToken.token.symbol
                                ) ?? "",
                                tokensChain: route.chainDescription(tokensList: state.swapTokens.map(\.token))
                            ),
                            networkFee: state.networkFee ?? SwapFeeInfo(
                                amount: 0.000005,
                                tokenSymbol: "SOL",
                                tokenName: "Solana",
                                tokenPriceInCurrentFiat: nil,
                                pct: 0.01,
                                canBePaidByKeyApp: true
                            ),
                            accountCreationFee: state.accountCreationFee ?? SwapFeeInfo(
                                amount: 0,
                                tokenSymbol: "SOL",
                                tokenName: "Solana",
                                tokenPriceInCurrentFiat: nil,
                                pct: 0,
                                canBePaidByKeyApp: false
                            ),
                            liquidityFee: state.liquidityFee,
                            minimumReceived: state.minimumReceivedAmount == nil ? nil: .init(
                                amount: state.minimumReceivedAmount!,
                                token: state.toToken.token.symbol
                            ),
                            exchangeRateInfo: state.exchangeRateInfo
                        )
                    )
                case .requiredInitialize, .initializing, .error:
                    return .empty
                default:
                    return .loading
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                self?.status = newStatus
            }
            .store(in: &subscriptions)
    }

    // MARK: - Actions
    
    func rowClicked(identifier: SwapSettingsView.RowIdentifier) {
        rowTappedSubject.send(identifier)
        log(fee: identifier)
    }
}

// MARK: - SwapSettingsViewModelIO

extension SwapSettingsViewModel: SwapSettingsViewModelIO {
    var rowTapped: AnyPublisher<SwapSettingsView.RowIdentifier, Never> {
        rowTappedSubject.eraseToAnyPublisher()
    }
}

// MARK: - Nested type

extension SwapSettingsViewModel {
    struct Info: Equatable {
        let routes: [SwapSettingsRouteInfo]
        var currentRoute: SwapSettingsRouteInfo
        let networkFee: SwapFeeInfo
        let accountCreationFee: SwapFeeInfo
        let liquidityFee: [SwapFeeInfo]
        let minimumReceived: SwapTokenAmountInfo?
        let exchangeRateInfo: String?
        
        var estimatedFees: String {
            "≈ " + (liquidityFee + [networkFee, accountCreationFee].compactMap { $0 })
                .compactMap(\.amountInFiat)
                .reduce(0.0, +)
                .formattedFiat()
        }
    }

    enum Status: Equatable {
        case loading
        case loaded(Info)
        case empty
        
        var info: Info? {
            switch self {
            case .loading, .empty:
                return nil
            case .loaded(let info):
                return info
            }
        }
        
        var isEmpty: Bool {
            switch self {
            case .loading, .loaded:
                return false
            case .empty:
                return true
            }
        }
    }
}

// MARK: - Analytics

extension SwapSettingsViewModel {
    func logRoute() {
        guard let currentRoute = info?.currentRoute.name else { return }
        analyticsManager.log(event: .swapSettingsSwappingThroughChoice(variant: currentRoute))
    }

    func log(slippage: Double) {
        let isCustom = slippage > 1
        if isCustom {
            analyticsManager.log(event: .swapSettingsSlippageCustom(slippageLevelPercent: slippage))
        } else {
            analyticsManager.log(event: .swapSettingsSlippage(slippageLevelPercent: slippage))
        }
    }

    private func log(fee: SwapSettingsView.RowIdentifier) {
        switch fee {
        case .route:
            analyticsManager.log(event: .swapSettingsFeeClick(feeName: "Swapping_Through"))
        case .networkFee:
            analyticsManager.log(event: .swapSettingsFeeClick(feeName: "Network_Fee"))
        case .accountCreationFee:
            analyticsManager.log(event: .swapSettingsFeeClick(feeName: "Sol_Account_Creation"))
        case .liquidityFee:
            analyticsManager.log(event: .swapSettingsFeeClick(feeName: "Liquidity_Fee"))
        default:
            break
        }
    }
}
