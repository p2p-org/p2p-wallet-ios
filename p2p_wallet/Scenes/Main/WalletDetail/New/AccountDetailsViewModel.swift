import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

enum AccountDetailsAction {
    case openBuy
    case openReceive
    case openSend
    case openSwap(SolanaAccount?)
    case openSwapWithDestination(SolanaAccount?, SolanaAccount?)
    case openCashOut
}

class AccountDetailsViewModel: BaseViewModel, ObservableObject {
    @Published var rendableAccountDetails: RendableAccountDetails
    @Published var banner: BannerItem?

    let actionSubject: PassthroughSubject<AccountDetailsAction, Never>

    init(rendableAccountDetails: RendableAccountDetails) {
        self.rendableAccountDetails = rendableAccountDetails
        actionSubject = .init()
    }

    /// Render solana account and dynamically update it.
    init(
        solanaAccountsManager: SolanaAccountsService = Resolver.resolve(),
        solanaAccount: SolanaAccountsService.Account,
        jupiterTokensRepository: JupiterTokensRepository = Resolver.resolve()
    ) {
        // Init action subject
        let actionSubject = PassthroughSubject<AccountDetailsAction, Never>()
        self.actionSubject = actionSubject

        // Handle action
        let onAction = { [weak actionSubject] (action: RendableAccountDetailsAction) in
            let analyticsManager: AnalyticsManager = Resolver.resolve()
            switch action {
            case .buy:
                analyticsManager.log(event: .tokenScreenBuyBar)
                actionSubject?.send(.openBuy)
            case .swap:
                actionSubject?.send(.openSwap(solanaAccount))
                analyticsManager.log(event: .tokenScreenSwapBar)
            case .send:
                analyticsManager.log(event: .tokenScreenSendBar)
                actionSubject?.send(.openSend)
            case .receive:
                analyticsManager.log(event: .tokenScreenReceiveBar)
                actionSubject?.send(.openReceive)
            case .cashOut:
                actionSubject?.send(.openCashOut)
            }
        }

        // Render solana wallet (account)
        rendableAccountDetails = RendableNewSolanaAccountDetails(
            account: solanaAccount,
            isSwapAvailable: false,
            onAction: onAction
        )

        super.init()

        // Dynamic updating wallet and render it
        let solanaAccountPublisher = solanaAccountsManager
            .statePublisher
            .receive(on: RunLoop.main)
            .compactMap { $0.value.first(where: { $0.address == solanaAccount.address }) }

        let jupiterDataStatusPublisher = jupiterTokensRepository.status

        Publishers.CombineLatest(solanaAccountPublisher, jupiterDataStatusPublisher)
            .map { account, status in
                RendableNewSolanaAccountDetails(
                    account: account,
                    isSwapAvailable: Self.isSwapAvailableFor(wallet: account, for: status),
                    onAction: onAction
                )
            }
            .sink { [weak self] rendableAccountDetails in
                self?.rendableAccountDetails = rendableAccountDetails
            }
            .store(in: &subscriptions)

        // Banner
        if available(.ethAddressEnabled) {
            // Token support to transfer to ethereum network, but required swap before that.
            let supportedTokens = [
                SolanaToken.usdc.mintAddress: SolanaToken.usdcet,
                SolanaToken.usdt.mintAddress: Wormhole.SupportedToken.usdt,
            ]

            if let supportedWormholeToken = supportedTokens[solanaAccount.token.mintAddress],
               !Defaults.ethBannerShouldHide
            {
                banner = .init(
                    title: L10n.toSendToEthereumNetworkYouHaveToSwapItTo(
                        solanaAccount.token.symbol,
                        supportedWormholeToken.symbol
                    ),
                    action: { [weak actionSubject] in
                        actionSubject?
                            .send(
                                .openSwapWithDestination(
                                    solanaAccount,
                                    .classicSPLTokenAccount(
                                        address: "",
                                        lamports: 0,
                                        token: supportedWormholeToken
                                    )
                                )
                            )
                    }, close: { [weak self] in
                        Defaults.ethBannerShouldHide = true
                        self?.banner = nil
                    }
                )
            }
        }
    }
}

extension AccountDetailsViewModel {
    /// Check swap action is available for this account (wallet).
    static func isSwapAvailableFor(wallet _: SolanaAccount, for status: JupiterDataStatus) -> Bool {
        // TODO(jupiter): Dynamic fetching data in future.
        switch status {
        case .ready:
            return true
        default:
            return false
        }
    }
}

extension AccountDetailsViewModel {
    struct BannerItem {
        let title: String
        let action: () -> Void
        let close: () -> Void
    }
}
