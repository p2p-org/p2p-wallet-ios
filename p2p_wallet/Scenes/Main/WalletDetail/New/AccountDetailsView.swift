import SwiftUI

struct AccountDetailsView: View {
    @ObservedObject var detailAccount: AccountDetailsViewModel
    @ObservedObject var historyList: HistoryViewModel

    var body: some View {
        NewHistoryView(viewModel: historyList, header: header)
            .background(Color(.smoke).ignoresSafeArea())
    }

    var header: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(detailAccount.rendableAccountDetails.amountInToken)
                    .fontWeight(.bold)
                    .apply(style: .largeTitle)
                    .foregroundColor(Color(.night))
                Text(detailAccount.rendableAccountDetails.amountInFiat)
                    .apply(style: .text3)
                    .foregroundColor(Color(.night))
            }
            .padding(.top, 24)

            HStack(spacing: detailAccount.rendableAccountDetails.actions.count > 3 ? 12 : 32) {
                ForEach(detailAccount.rendableAccountDetails.actions) { action in

                    Button(
                        action: {
                            detailAccount.rendableAccountDetails.onAction(action)
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

            if let banner = detailAccount.banner {
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
}

struct AccountDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let historyList = HistoryViewModel(
            mock: [MockedRendableListTransactionItem.send()]
        )
        historyList.fetch()

        return AccountDetailsView(
            detailAccount: .init(
                rendableAccountDetails: MockRendableAccountDetails(
                    title: "USDC",
                    amountInToken: "1 000.97 USDC",
                    amountInFiat: "1 000.97 USDC",
                    actions: [.cashOut, .buy, .receive(.none), .send, .swap(nil)],
                    onAction: { _ in }
                )
            ),
            historyList: historyList
        )
    }
}
