import SwiftUI
import Combine
import KeyAppUI

struct SentViaLinkHistoryView: View {
    // MARK: - Nested type

    struct SVLSection: Identifiable {
        let id: String
        var transactions: [SendViaLinkTransactionInfo]
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
            .onReceive(transactionsPublisher, perform: onReceive(transactions:))
    }
    
    // MARK: - ViewBuilders
    
    @ViewBuilder
    private func sectionHeaderView(section: SVLSection) -> some View {
        HStack {
            Text(section.id.uppercased())
                .fontWeight(.semibold)
                .apply(style: .caps)
                .foregroundColor(Color(Asset.Colors.mountain.color))
            Spacer()
        }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(Asset.Colors.smoke.color))
    }

    @ViewBuilder
    private func transactionView(
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
    
    // MARK: - Helpers
    
    private func onReceive(transactions: [SendViaLinkTransactionInfo]) {
        // sort transaction
        let sortedTransactions = transactions
            .sorted(by: {$0.timestamp > $1.timestamp})
        
        // group transactions into section
        var sections = [SVLSection]()
        for transaction in sortedTransactions {
            // if sections exists
            if let index = sections.firstIndex(
                where: { $0.id == transaction.creationDayInString }
            ) {
                sections[index].transactions.append(transaction)
            }
            // else create section
            else {
                sections.append(
                    .init(
                        id: transaction.creationDayInString,
                        transactions: [transaction]
                    )
                )
            }
        }
        self.sections = sections
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
