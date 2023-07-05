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
            switch action {
            case .buy:
                actionSubject?.send(.openBuy)
            case .swap:
                actionSubject?.send(.openSwap(solanaAccount))
            case .send:
                actionSubject?.send(.openSend)
            case .receive:
                actionSubject?.send(.openReceive)
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
                SolanaToken.usdc.address: SolanaToken.usdcet,
                SolanaToken.usdt.address: Wormhole.SupportedToken.usdt,
            ]

            if let supportedWormholeToken = supportedTokens[solanaAccount.token.address], !Defaults.ethBannerShouldHide {
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
                                    SolanaAccount(token: supportedWormholeToken)
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
    static func isSwapAvailableFor(wallet: SolanaAccount, for status: JupiterDataStatus) -> Bool {
        switch status {
        case let .ready(swapTokens, _) where swapTokens.contains(where: { $0.address == wallet.mintAddress }):
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
