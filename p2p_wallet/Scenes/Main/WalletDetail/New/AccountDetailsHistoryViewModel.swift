import Foundation
import KeyAppBusiness
import KeyAppKitCore
import History
import Resolver
import SolanaSwift

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
                        self?.actionSubject.send(.openSwap(self?.account?.data))
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
