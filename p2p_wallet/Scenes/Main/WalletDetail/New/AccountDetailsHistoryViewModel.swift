import Foundation
import History
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

final class AccountDetailsHistoryViewModel: HistoryViewModel {
    @Injected private var helpLauncher: HelpCenterLauncher

    let account: SolanaAccount

    init(
        mint: String,
        account: SolanaAccount
    ) {
        self.account = account
        super.init(mint: mint)
    }

    override func buildOutput(
        history: ListState<any RendableListTransactionItem>,
        sells: [any RendableListOfframItem] = [],
        pendings: [any RendableListTransactionItem] = []
    ) -> ListState<HistorySection> {
        var state = super.buildOutput(history: history, sells: sells, pendings: pendings)

        // Check send to wormhole if feature flag is active.
        guard available(.ethAddressEnabled) else {
            return state
        }

        // Token support to transfer to ethereum network, but required swap before that.
        let supportedTokens = [
            SolanaToken.usdc.address: SolanaToken.usdcet,
            SolanaToken.usdt.address: Wormhole.SupportedToken.usdt,
        ]

        if let supportedWormholeToken = supportedTokens[account.data.token.address] {
            // Create banner to notify user.
            let bannerSection = HistorySection(
                title: "",
                items: [
                    .swapBanner(
                        id: UUID().uuidString,
                        text: L10n.toMakeATransferToYouHaveToSwapTo(
                            "ETH",
                            account.data.token.symbol,
                            supportedWormholeToken.name
                        ),
                        buttonTitle: "\(L10n.swap.capitalized) \(account.data.token.symbol) → \(supportedWormholeToken.name)",
                        action: { [weak self] in
                            self?.actionSubject
                                .send(.openSwap(self?.account.data, Wallet(token: supportedWormholeToken)))
                        },
                        helpAction: { [weak self] in
                            self?.helpLauncher.launch()
                        }
                    ),
                ]
            )

            state.data.insert(bannerSection, at: 0)
        }

        return state
    }
}
