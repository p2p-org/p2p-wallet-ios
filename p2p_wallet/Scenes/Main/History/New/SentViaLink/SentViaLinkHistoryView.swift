import SwiftUI
import Combine

struct SentViaLinkHistoryView: View {
    // MARK: - Properties
    
    let transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never>
    @State var transactions: [SendViaLinkTransactionInfo] = []
    
    let onSelectTransaction: (SendViaLinkTransactionInfo) -> Void
    
    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(transactions) { transaction in
                    transactionView(transaction: transaction)
                }
            }
        }
            .onReceive(transactionsPublisher) { transactions in
                self.transactions = transactions
            }
    }
    
    // MARK: - ViewBuilder

    @ViewBuilder
    func transactionView(
        transaction: SendViaLinkTransactionInfo
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(uiImage: .sendViaLinkCircleCompleted)
                .resizable()
                .frame(width: 48, height: 48)
            
            Text(L10n.sentViaOneTimeLink)
                .fontWeight(.semibold)
                .apply(style: .text3)
            
            Spacer()
            
            Text(transaction.amount.tokenAmountFormattedString(
                symbol: transaction.token.symbol,
                maximumFractionDigits: Int(transaction.token.decimals)
            ))
                .fontWeight(.semibold)
                .apply(style: .text3)
        }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelectTransaction(transaction)
            }
    }
}

#if DEBUG
struct SentViaLinkHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SentViaLinkHistoryView(
            transactionsPublisher: Just(.mocked)
                .eraseToAnyPublisher(),
            onSelectTransaction: { _ in }
        )
    }
}
#endif
