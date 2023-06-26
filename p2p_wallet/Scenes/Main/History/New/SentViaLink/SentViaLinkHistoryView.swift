import AnalyticsManager
import SwiftUI
import Combine
import KeyAppUI
import Resolver

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
                    sectionView(section: section)
                }
            }
        }
            .background(Color(Asset.Colors.smoke.color))
            .onReceive(transactionsPublisher, perform: onReceive(transactions:))
    }
    
    // MARK: - ViewBuilders
    
    @ViewBuilder
    private func sectionView(section: SVLSection) -> some View {
        Section(header: sectionHeaderView(section: section)) {
            ForEach(0..<section.transactions.count, id: \.self) { index in
                SentViaLinkHistoryTransactionView(
                    transaction: section.transactions[index]
                )
                    .background(Color(Asset.Colors.snow.color))
                    .cornerRadius(radius: 16, index: index, itemsCount: section.transactions.count)
                    .onTapGesture {
                        Resolver.resolve(AnalyticsManager.self).log(event: .historySendClickTransaction)
                        onSelectTransaction(section.transactions[index])
                    }
            }
        }
            .padding(.horizontal, 12)
    }
    
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

private extension View {
    func cornerRadius(radius: CGFloat, index: Int, itemsCount: Int) -> some View {
        var corner = UIRectCorner()
        if index == 0 {
            corner.insert([.topLeft, .topRight])
        }
        if index == itemsCount - 1 {
            corner.insert([.bottomLeft, .bottomRight])
        }
        return cornerRadius(radius: radius, corners: corner)
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
