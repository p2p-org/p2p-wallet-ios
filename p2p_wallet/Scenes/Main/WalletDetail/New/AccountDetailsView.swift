import PnLService
import Repository
import Resolver
import SwiftUI

struct AccountDetailsView: View {
    @ObservedObject var viewModel: AccountDetailsViewModel
    @ObservedObject var historyListViewModel: HistoryViewModel

    var body: some View {
        NewHistoryView(viewModel: historyListViewModel, header: header)
            .background(Color(.smoke).ignoresSafeArea())
    }

    var header: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(viewModel.rendableAccountDetails.amountInToken)
                    .fontWeight(.bold)
                    .apply(style: .largeTitle)
                    .foregroundColor(Color(.night))
                Text(viewModel.rendableAccountDetails.amountInFiat)
                    .apply(style: .text3)
                    .foregroundColor(Color(.night))

                if available(.pnlEnabled),
                   let account = viewModel.rendableAccountDetails as? RendableNewSolanaAccountDetails
                {
                    RepositoryView(
                        repository: Resolver.resolve(PnLRepository.self)
                    ) { _ in
                        Rectangle()
                            .skeleton(with: true, size: .init(width: 100, height: 16))
                    } errorView: { error, pnl in
                        #if !RELEASE
                            VStack {
                                pnlContentView(pnl: pnl, mint: account.account.mintAddress)
                                Text(String(reflecting: error))
                                    .foregroundStyle(.red)
                            }
                        #else
                            pnlContentView(pnl: pnl)
                        #endif
                    } content: { pnl in
                        pnlContentView(pnl: pnl, mint: account.account.mintAddress)
                    }
                    .frame(height: 16)
                    .padding(.top, 12)
                }
            }
            .padding(.top, 24)

            HStack(spacing: viewModel.rendableAccountDetails.actions.count > 3 ? 12 : 32) {
                ForEach(viewModel.rendableAccountDetails.actions) { action in

                    Button(
                        action: {
                            viewModel.rendableAccountDetails.onAction(action)
                        },
                        label: {
                            VStack(spacing: 4) {
                                Image(action.icon)
                                    .resizable()
                                    .frame(width: 52, height: 52)
                                    .scaledToFit()
                                Text(action.title)
                                    .fontWeight(.semibold)
                                    .apply(style: .label2)
                                    .foregroundColor(Color(.night))
                            }
                        }
                    )
                }
            }
            .padding(.top, 32)

            if let banner = viewModel.banner {
                SwapEthBanner(text: banner.title, action: banner.action, close: {
                    withAnimation {
                        banner.close()
                    }
                })
                .padding(.all, 16)
                .padding(.top, 16)
            }
        }
    }

    @ViewBuilder private func pnlContentView(
        pnl: PnLModel?,
        mint: String
    ) -> some View {
        if let percentage = pnl?.pnlByMint[mint]?.percent {
            Text(L10n.last24h("\(percentage)"))
                .font(uiFont: .font(of: .text3))
                .foregroundColor(Color(.night))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.snow))
                .cornerRadius(8)
                .onTapGesture {
                    viewModel.actionSubject.send(.openPnL)
                }
        }
    }
}

struct AccountDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let historyList = HistoryViewModel(
            mock: [MockedRendableListTransactionItem.send()]
        )
        historyList.fetch()

        return AccountDetailsView(
            viewModel: .init(
                rendableAccountDetails: MockRendableAccountDetails(
                    title: "USDC",
                    amountInToken: "1 000.97 USDC",
                    amountInFiat: "1 000.97 USDC",
                    actions: [.cashOut, .buy, .receive(.none), .send, .swap(nil)],
                    onAction: { _ in }
                )
            ),
            historyListViewModel: historyList
        )
    }
}
