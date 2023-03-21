import Foundation
import KeyAppBusiness
import KeyAppKitCore
import History
import Resolver
import SolanaSwift
import Wormhole

final class DetailHistoryViewModel: HistoryViewModel {
    @Injected private var helpLauncher: HelpCenterLauncher
    let account: SolanaAccountsService.Account?

    init(
        mint: String,
        account: SolanaAccountsService.Account? = nil
    ) {
        self.account = account
        super.init(mint: mint)
    }

    override func buildOutput(
        history: ListState<any RendableListTransactionItem>,
        sells: [any RendableListOfframItem] = [],
        pendings: [any RendableListTransactionItem] = []
    ) -> ListState<HistorySection> {
        let bannerSection = HistorySection(
            title: "",
            items: [
                .swapBanner(
                    id: UUID().uuidString,
                    text: L10n.toMakeATransferToYouHaveToSwapTo("ETH", account?.data.token.symbol ?? "", "USDCet"),
                    buttonTitle: "\(L10n.swap.capitalized) \(account?.data.token.symbol ?? "") → USDCet",
                    action: { [weak self] in
                        self?.actionSubject.send(.openSwap(self?.account?.data, Wallet(token: .usdcet)))
                    },
                    helpAction: { [weak self] in
                        self?.helpLauncher.launch()
                    }
                )
            ]
        )

        let state = super.buildOutput(history: history, sells: sells, pendings: pendings)
        var newData = state.data
        newData.insert(bannerSection, at: 0)
        return .init(
            status: state.status,
            data: newData,
            fetchable: state.fetchable,
            error: state.error
        )
    }
}

private extension Token {
    static var usdcet: Self {
        .init(
            _tags: nil,
            chainId: 101,
            address: SupportedToken.ERC20.usdc.solanaMintAddress,
            symbol: "USDCet",
            name: "USD Coin (Wormhole)",
            decimals: 6,
            logoURI: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/A9mUU4qviSctJVPJdBJWkb28deg915LYJKrzQ19ji3FM/logo.png",
            extensions: .init(coingeckoId: "usd-coin")
        )
    }
}
