import Foundation
import KeyAppBusiness
import KeyAppKitCore
import History
import Resolver
import SolanaSwift
import Wormhole

final class AccountDetailsHistoryViewModel: HistoryViewModel {

    @Injected private var helpLauncher: HelpCenterLauncher

    let account: SolanaAccount?

    init(
        mint: String,
        account: SolanaAccount? = nil
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
                    text: L10n.toMakeATransferToYouHaveToSwapTo("ETH", account?.data.token.symbol ?? "", Token.usdcet.symbol),
                    buttonTitle: "\(L10n.swap.capitalized) \(account?.data.token.symbol ?? "") → \(Token.usdcet.symbol)",
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
        let supportedBridgeTokens = Wormhole.SupportedToken.bridges.filter { ["USDC", "USDT"].contains($0.name) }
            .map(\.solAddress)
            .compactMap { $0 } +
        Wormhole.SupportedToken.bridges.filter { ["USDC", "USDT"].contains($0.name) }
            .map(\.receiveFromAddress)
            .compactMap { $0 }
        if available(.ethAddressEnabled),
            supportedBridgeTokens.contains(account?.data.token.address ?? "") {
            newData.insert(bannerSection, at: 0)
        }
        return .init(
            status: state.status,
            data: newData,
            fetchable: state.fetchable,
            error: state.error
        )
    }
}
