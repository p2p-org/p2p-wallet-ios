import SwiftUI
import Combine
import KeyAppUI

struct SentViaLinkHistoryView: View {
    // MARK: - Nested type

    struct SVLSection: Identifiable {
        let id: String
        let transactions: [SendViaLinkTransactionInfo]
    }
    
    // MARK: - Properties
    
    let transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never>
    @State var sections: [SVLSection] = []
    
    let onSelectTransaction: (SendViaLinkTransactionInfo) -> Void
    
    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(sections) { section in
                    Section(header: sectionHeaderView(section: section)) {
                        ForEach(section.transactions) { transaction in
                            transactionView(transaction: transaction)
                        }
                    }
                }
            }
        }
            .onReceive(transactionsPublisher) { transactions in
                // group transactions into section
                self.sections = Dictionary(grouping: transactions) { transaction in
                    
                    // get transaction timestamp
                    let timestamp = transaction.timestamp
                    
                    // if today
                    if Calendar.current.isDateInToday(timestamp) {
                        return L10n.today
                    }
                    
                    // if another day
                    else {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MMMM d, yyyy"
                        let someDateString = dateFormatter.string(from: timestamp)
                        return someDateString
                    }
                }
                    .map { key, value in
                        .init(id: key, transactions: value)
                    }
            }
    }
    
    // MARK: - ViewBuilders
    
    @ViewBuilder
    func sectionHeaderView(section: SVLSection) -> some View {
        HStack {
            Text(section.id.uppercased())
                .fontWeight(.semibold)
                .apply(style: .caps)
                .foregroundColor(Color(Asset.Colors.mountain.color))
            Spacer()
        }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
    }

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
                .layoutPriority(1)
            
            Spacer(minLength: 0)
            
            Text(transaction.amount.tokenAmountFormattedString(
                symbol: transaction.token.symbol,
                maximumFractionDigits: Int(transaction.token.decimals)
            ))
                .fontWeight(.semibold)
                .apply(style: .text3)
                .multilineTextAlignment(.trailing)
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
